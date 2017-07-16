#!/bin/bash
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }; set_dir
safe_source () { source $1; set_dir; }

echo "updating dcs-tools..."
cd $DIR
git pull origin master
git submodule update --init --recursive
