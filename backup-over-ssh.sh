#!/bin/bash

# This script copies whole root directory of target to backup location

# ###################################################################
# INSTALL
# add following line to remote (source) machine's /etc/sudoers file :
# YOUR_SSH_USER ALL=(ALL) NOPASSWD: /usr/bin/rsync
# ###################################################################

set -e

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

if [[ $(id -u) > 0 ]]; then
    #echo "This script needs root privileges..."
    sudo $0 "$@"
    exit
fi

safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/fs-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh

backup=
source=
RSYNC="nice -n19 ionice -c3 rsync"
init=false

show_help () {
    cat <<HELP

    Usage:

        $(basename $0) ...options...

    Options:

    --backup        : backup directory
    --source        : source address: "ssh://user@host:[port]/folder/to/backup"
    --init          : initialize remote source if not initialized

HELP
}

die () {
    errcho "ERROR: "
    errcho "ERROR: $@"
    errcho "ERROR: "
    show_help
    exit 255
}

while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        --backup)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                backup=$(realpath $2)
                shift
            else
                die '"--backup" requires a non-empty option argument.'
            fi
            ;;
        --source)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                source=$2
                shift
            else
                die '"--source" requires a non-empty option argument.'
            fi
            ;;
        --init)
            init=true
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

if [ ! $source ]; then
    die "SSH address is required."
else
    SSH_PORT=$(parse_url port $source)
    SSH_HOST=$(parse_url host $source)
    SSH_USER=$(parse_url user $source)
    SSH_PATH=$(parse_url path $source)

    # defaults
    [ $SSH_PORT ] || SSH_PORT="22"

    SSH_KEY_FILE="/home/$SUDO_USER/.ssh/id_rsa"
    echo_yellow $SSH_KEY_FILE
    echo_green "Using source: $source, port: $SSH_PORT addr: $SSH_HOST, user: $SSH_USER, path: $SSH_PATH"
fi

if $init; then
    echo "Copying ssh key file to source host"
    if check_ssh_key; then
        echo_green "Key file is already installed on source host."
    else
        echo_yellow "Key file will be installed!"
        PUBLIC_KEY=$(get_public_key $SSH_KEY_FILE)
        $SSH $SSH_USER@$SSH_HOST -p $SSH_PORT \
        "export KEY='$PUBLIC_KEY'" '; bash -s' <<'ENDSSH'
            # commands to run on remote host
            AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"

            # create needed files and directories if not exists:
            mkdir -p $(dirname "$AUTHORIZED_KEYS_FILE")
            touch "$AUTHORIZED_KEYS_FILE"

            #echo "Executing remote commands"

            echo "-------public key--------"
            echo $KEY
            echo "-------------------------"

            grep "$KEY" $AUTHORIZED_KEYS_FILE > /dev/null
            if [[ $? -eq 0 ]]; then
                echo Public key already exists
            else
                echo Adding public key to $AUTHORIZED_KEYS_FILE file
                echo $KEY >> $AUTHORIZED_KEYS_FILE
            fi
ENDSSH
    fi
    mycmd=`cat <<'EOF'
        SUDOERS_LINE="$SUDO_USER ALL=(ALL) NOPASSWD: /usr/bin/rsync";
        if ! sudo grep "$SUDOERS_LINE" /etc/sudoers > /dev/null; then
            echo "Adding rsync authorization line in /etc/sudoers";
            echo $SUDOERS_LINE | tee -a /etc/sudoers;
        else
            echo "rsync is already authorized to run without password.";
        fi
EOF
`
    cmd_encoded=$(echo $mycmd | base64 -w0)
    ssh_id_command "echo $cmd_encoded | base64 -d | sudo bash"

    echo_green "Remote source is initialized. Exiting."
    exit 0
fi

if [[ ! -d $backup ]]; then
    die "Backup directory must exist: $backup"
else
    echo_green "Using backup directory: $backup"
fi

if prompt_yes_no "Should we really continue?"; then
    echo_yellow "Backups will go to: $backup"
else
    echo_info "Interrupted by user."
    exit 0
fi

start_timer

$RSYNC -aHAXvPh --delete --delete-excluded --exclude-from "$DIR/exclude-list.txt" \
	--rsh="ssh -p $SSH_PORT -i $SSH_KEY_FILE" --rsync-path="sudo rsync" $SSH_USER@$SSH_HOST:$SSH_PATH $backup

show_timer "Backup completed in:"
