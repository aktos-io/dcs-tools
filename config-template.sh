# Direct (on LAN) connection settings:
# ------------------------------------
NODE_IP="xx.yy.zz.tt"
#NODE_PORT=22
#NODE_USER="aea"
#KEY_FILE="$HOME/.ssh/id_rsa"
#MOUNT_DIR=$(mktemp -d)


# Proxy connection settings
# ------------------------------------
# create master socket first: 
#
#     ssh you@example.com -p 1234 -M -S /path/to/ssh-master-you@example.com:1234.socket
#
SSH_SOCKET_FILE="/path/to/ssh-master-you@example.com:1234.socket"
NODE_RENDEZVOUS_PORT=7000
