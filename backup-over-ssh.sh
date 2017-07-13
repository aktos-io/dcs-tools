#!/bin/bash

# This script copies whole root directory of target to backup location

# INSTALL
# add following line to remote (source) machine's /etc/sudoers file :
# aea ALL=(ALL) NOPASSWD: /usr/bin/rsync


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

show_help () {
    cat <<HELP

    Usage:

        $(basename $0) ...options...

    Options:

    --backup        : backup directory
    --source        : source address: "ssh://ip"

HELP
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
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

if [[ ! -d $backup ]]; then
    die "Backup directory must exist: $backup"
else
    echo_green "Using backup directory: $backup"
fi


if [ ! $source ]; then
    die "SSH address is required."
else
    SOURCE_PORT=$(parse_url port $source)
    ADDR=$(parse_url host $source)
    USER=$(parse_url user $source)
    REMOTE_PATH=$(parse_url path $source)

    # defaults
    [ $SOURCE_PORT ] || SOURCE_PORT="22"

    ID="/home/$SUDO_USER/.ssh/id_rsa"
    echo_yellow $ID
    echo_green "Using source: $source, port: $SOURCE_PORT addr: $ADDR, user: $USER, path: $REMOTE_PATH"
fi

start_timer

if prompt_yes_no "Should we really continue?"; then
    echo_yellow "Backups will go to: $backup"
else
    echo_info "Interrupted by user."
    exit 0
fi


$RSYNC -aHAXvPh --delete --delete-excluded --exclude-from "$DIR/exclude-list.txt" \
	--rsh="ssh -p $SOURCE_PORT -i $ID" --rsync-path="sudo rsync" $USER@$ADDR:$REMOTE_PATH $backup


# direct sync
#			time $(RSYNC) -aHAXvPh \
#				--delete \
#				--delete-excluded \
#				--exclude-from $(TOOLS_DIR)/'exclude-list.txt' \
#				--rsh='ssh -p $(NODE_LOCAL_SSHD_PORT) -i $(SSH_KEY_FILE)' root@$(NODE_LOCAL_IP):/  $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) 2> $(LAST_ERR_LOG) || { exit 1; } ;\


show_timer "Backup completed in:"
