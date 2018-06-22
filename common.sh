#!/bin/bash
set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }; set_dir
safe_source () { source $1; set_dir; }

safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/ssh-functions.sh

CONFIG=$DIR/../config.sh
if [[ ! -f $CONFIG ]]; then
    echo_yellow "You need to configure first, run './setup'"
    exit
fi

# Grab the user configuration and parse the variables, assign the defaults
safe_source $CONFIG

USER_HOME=$(eval echo ~${SUDO_USER})
USER_NAME=$(logname)

# set the default configuration
[ $NODE_USER ] || NODE_USER="aea"
if [[ ! -z $NODE_ADDR ]]; then
    NODE_IP=${NODE_ADDR%:*}
    NODE_PORT=${NODE_ADDR#*:}
    [ $NODE_PORT == $NODE_IP ] && NODE_PORT=
fi
[ $NODE_PORT ] || NODE_PORT=22
#echo "Node addr: $NODE_ADDR, node ip: $NODE_IP, node port: $NODE_PORT"

[ $KEY_FILE ] || KEY_FILE="$USER_HOME/.ssh/id_rsa"
[ $MOUNT_DIR ] || MOUNT_DIR=$(mktemp -d)
if [ $PROXY_ADDR ]; then
    [ $PROXY_USER ] || die "Linkup server username is required"
    PROXY_HOST=${PROXY_ADDR%:*}
    PROXY_PORT=${PROXY_ADDR#*:}
    [ $PROXY_PORT == $PROXY_HOST ] && PROXY_PORT=22
    [ $NODE_PROXY_PORT ] || die "NODE Linkup port is required"
    #echo "Linkup server is set up: $PROXY_HOST on port $PROXY_PORT --> $NODE_PROXY_PORT"
fi

SSH_CONFIG=$(realpath "$DIR/../ssh-config")
NODE_MOUNT_LINK="$DIR/../NODE_ROOT"
known_hosts_file=$(realpath $DIR/../known_hosts)
touch $known_hosts_file

# match with all hosts
sed 's/^[^ ]* /\* /' $known_hosts_file > "${known_hosts_file}.bak111" && mv "${known_hosts_file}.bak111" $known_hosts_file
chown $USER_NAME $known_hosts_file

custom_known_hosts="-o UserKnownHostsFile=$known_hosts_file \
    -o StrictHostKeyChecking=ask \
    -o CheckHostIP=no "


SSH="$SSH $custom_known_hosts -o HashKnownHosts=no -F $SSH_CONFIG "
SSHFS="$SSHFS $custom_known_hosts -F $SSH_CONFIG "
