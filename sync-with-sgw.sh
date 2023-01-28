#!/usr/bin/env bash
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -eu 

show_help(){
    cat <<HELP
    $(basename $0) -c path/to/config

    Synchronizes the directory that the configuration file present with \$dest_dir
    Always excluded paths: '.git'

    Options:

        --dry-run   : Runs RSYNC in dry run mode. 

    Configuration (a valid BASH script): 

        proxy_host="USER@HOST:PORT"             # SSH host to use as the jump server
        proxy_host="foo"                        # Same as above, use "foo" target from .ssh/config

        dest_host="USER@HOST:PORT"              # Destination host 
        dest_host="bar"                         # Destination host from .ssh/config

        dest_dir='./path/to/dest_dir/'          # Notice the / at the end 

        use_gitignore=true                      # use .gitignore file to extract exclude dirs
        run_before_sync+=("path/to/hookscript") # execute those scripts before sync

HELP
}

die(){
    >&2 echo
    >&2 echo "$@"
    exit 1
}

help_die(){
    >&2 echo
    >&2 echo "$@"
    show_help
    exit 1
}

# Parse command line arguments
# ---------------------------
# Initialize parameters
config=
dry_run=
# ---------------------------
args_backup=("$@")
args=()
_count=1
while [ $# -gt 0 ]; do
    key="${1:-}"
    case $key in
        -h|-\?|--help|'')
            show_help    # Display a usage synopsis.
            exit
            ;;
        # --------------------------------------------------------
        -c|--config) shift
            config="$1"
            ;;
        --dry-run)
            dry_run="--dry-run"
            ;;
        # --------------------------------------------------------
        -*) # Handle unrecognized options
            help_die "Unknown option: $1"
            ;;
        *)  # Generate the new positional arguments: $arg1, $arg2, ... and ${args[@]}
            if [[ ! -z ${1:-} ]]; then
                declare arg$((_count++))="$1"
                args+=("$1")
            fi
            ;;
    esac
    [[ -z ${1:-} ]] && break || shift
done; set -- "${args_backup[@]-}"
# Use $arg1 in place of $1, $arg2 in place of $2 and so on, 
# "$@" is in the original state,
# use ${args[@]} for new positional arguments  

[[ -f "$config" ]] || die "Configuration file is required."
source "$config"

SRC_DIR="$(dirname "$config")"

read SGW_USERNAME SGW_HOST SGW_PORT_ON_SERVER <<< $(echo $dest_host | sed 's/@/ /' | sed 's/:/ /')
[[ -z $SGW_HOST ]] && { SGW_HOST=$SGW_USERNAME; SGW_USERNAME=''; }
read PROXY_USERNAME PROXY_HOST PROXY_PORT <<< $(echo $proxy_host | sed 's/@/ /' | sed 's/:/ /')
[[ -z $PROXY_HOST ]] && { PROXY_HOST=$PROXY_USERNAME; PROXY_USERNAME=''; }

ignores=(--exclude '.git')
gitignore_file="$SRC_DIR/.gitignore"
if ${use_gitignore:-false} && [[ -f "$gitignore_file" ]]; then 
    while IFS=: read -r line; do
        ignores+=(--exclude "$line")
    done < <(grep "" "$gitignore_file") 
fi

script_name="$(basename $0)"

echo_blue () {
    echo -e "\e[1;34m$*\e[0m"
}

echo_yellow () {
    echo -e "\e[1;33m$*\e[0m"
}

echo_green () {
    echo -e "\e[1;32m$*\e[0m"
}

RSYNC="nice -n19 ionice -c3 rsync"

timestamp(){
    date +'%Y-%m-%d %H:%M'
}

previous_sync_failed=false
while :; do
    hook_failed=false
    for cmd in "${run_before_sync[@]}"; do
        echo_blue "Running hook before sync: $cmd"
        eval $cmd || { hook_failed=true; break; }
    done

    if ! $hook_failed; then 
        echo_blue "$(timestamp): Synchronizing..."

        [[ -z $dry_run ]] || set -x
        if $RSYNC -avzhP --delete $dry_run "${ignores[@]}" \
            -e "ssh -A -J ${PROXY_HOST} -p ${SGW_PORT_ON_SERVER}" \
            "$SRC_DIR" \
            ${SGW_USERNAME}@localhost:"${dest_dir}"; then 
        
            $previous_sync_failed && notify-send -u critical "$script_name Succeeded." "$(timestamp)"
        else
            period=10
            $previous_sync_failed || notify-send -u critical "$script_name Failed." "Retrying in $period seconds."
            sleep $period
            echo_yellow "Retrying..."
            previous_sync_failed=true
            continue
        fi
        $previous_sync_failed || notify-send "Sync done." "$(timestamp): ${dest_dir}"

        previous_sync_failed=false
    else 
        notify-send -u critical "$script_name Failed." "$cmd failed ($(timestamp))"
    fi

    echo_green "Waiting for directory changes..."
    inotifywait -q -e modify,create,delete -r "$SRC_DIR"
done
