#!/bin/bash
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/common.sh
PR=$(realpath $DIR/..)

if [[ -f $PR/method-hardlinks ]]; then
    METHOD="hardlinks"
elif [[ -f $PR/method-btrfs ]]; then
    METHOD="btrfs"
fi

if [[ $METHOD == "" ]]; then
    echo_err "Medhod is required. Put either method-btrfs or method-hardlinks file"
fi
$DIR/make-backup --method $METHOD --source $PR/sync-root --backups $PR/backups
