#!/bin/bash
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }; set_dir
safe_source () { source $1; set_dir; }

safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh

CONFIG=$DIR/../config.sh

if [[ -f $DIR/config.sh ]]; then
    echo_yellow "DEPRECATION:"
    echo_yellow "Configuration file (config.sh) should be in project directory"
    mv $DIR/config.sh $CONFIG
fi

if [[ ! -f $CONFIG ]]; then
    echo_yellow "You need to configure first"
    exit
fi

safe_source $CONFIG

# set the default configuration
[ $NODE_USER ] || NODE_USER="aea"
[ $KEY_FILE ] || KEY_FILE="$HOME/.ssh/id_rsa"
[ $MOUNT_DIR ] || MOUNT_DIR=$(mktemp -d)
[ $NODE_PORT ] || NODE_PORT=22
if [ $RENDEZVOUS_HOST ]; then
    [ $RENDEZVOUS_USER ] || die "Rendezvous username is required"
    [ $RENDEZVOUS_PORT ] || RENDEZVOUS_PORT=443
    [ $NODE_RENDEZVOUS_PORT ] || die "Target node's sshd port on rendezvous server is required"
    echo_green "Using rendezvous server: $RENDEZVOUS_USER@$RENDEZVOUS_HOST:$RENDEZVOUS_PORT -> $NODE_RENDEZVOUS_PORT"
fi

NODE_MOUNT_LINK="$DIR/../NODE_ROOT"

known_hosts_file=$(realpath $DIR/../known_hosts)
touch $known_hosts_file

# match with all hosts
sed 's/^[^ ]* /\* /' $known_hosts_file > "${known_hosts_file}.bak111" && mv "${known_hosts_file}.bak111" $known_hosts_file

custom_known_hosts="-o UserKnownHostsFile=$known_hosts_file \
    -o StrictHostKeyChecking=ask \
    -o CheckHostIP=no "

SSH="$SSH $custom_known_hosts -o HashKnownHosts=no "
SSHFS="$SSHFS $custom_known_hosts"
