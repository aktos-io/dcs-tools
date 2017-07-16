#!/bin/bash

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

$DIR/create-bootable-disk.sh --skip-format "$@"
