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

start_timer

retry_count=1
while :; do
    $RSYNC -aHAXvPh --delete --delete-excluded --exclude-from "$DIR/exclude-list.txt" \
	    --rsh="$SSH" --rsync-path="sudo rsync" target_$conn_method:$source $sync_dir && break || true
    echo "Retrying in 10 seconds (retry_count=$retry_count)..."
    notify-send -u critical "Retrying sync" "retry_count=$retry_count"
    ((retry_count++))
    sleep 10
done
echo "Total retry_count is $retry_count"
show_timer "sync completed in:"
