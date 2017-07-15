#!/bin/bash

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

safe_source $DIR/config.sh
safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh

[ $NODE_USER ] || NODE_USER="aea"
[ $KEY_FILE ] || KEY_FILE="$HOME/.ssh/id_rsa"
[ $MOUNT_DIR ] || MOUNT_DIR=$(mktemp -d)
[ $NODE_IP ] || die "Node IP is required!"
[ $NODE_PORT ] || NODE_PORT=22

echo_green "Target: $NODE_USER@$NODE_IP:$NODE_PORT"
if [ $RENDEZVOUS_HOST ]; then
    [ $RENDEZVOUS_USER ] || die "Rendezvous username is required"
    [ $RENDEZVOUS_PORT ] || RENDEZVOUS_PORT=443
    [ $NODE_RENDEZVOUS_PORT ] || die "Target node's sshd port on rendezvous server is required"
    echo_green "Using rendezvous server: $RENDEZVOUS_USER@$RENDEZVOUS_HOST:$RENDEZVOUS_PORT -> $NODE_RENDEZVOUS_PORT"
fi

NODE_MOUNT_LINK="$DIR/../NODE_ROOT"
