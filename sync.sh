#!/bin/bash
set -e
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

if [[ $(id -u) > 0 ]]; then sudo $0 "$@"; exit; fi

safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/fs-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh

safe_source $DIR/common.sh
$DIR/create-ssh-config

sync_dir=$(realpath $DIR/../sync-root)
source="/"
RSYNC="nice -n19 ionice -c3 rsync"

die () {
    errcho "ERROR: "
    errcho "ERROR: $@"
    errcho "ERROR: "
    show_help
    exit 255
}

conn_method=$1
[ $conn_method ] || die "Connection method must be provided"

if [[ ! -d $sync_dir ]]; then
    die "sync directory must exist: $sync_dir"
else
    echo_green "Using sync directory: $sync_dir"
fi

if prompt_yes_no "Should we really continue?"; then
    echo_yellow "syncs will go to: $sync_dir"
else
    echo_info "Interrupted by user."
    exit 0
fi

start_timer

$RSYNC -aHAXvPh --delete --delete-excluded --exclude-from "$DIR/exclude-list.txt" \
	--rsh="$SSH" --rsync-path="sudo rsync" target_$conn_method:$source $sync_dir

show_timer "sync completed in:"
