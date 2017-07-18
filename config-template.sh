# Direct connection settings:
# ------------------------------------
NODE_IP="xx.yy.zz.tt"
#NODE_USER="aea"
#NODE_PORT=22
#KEY_FILE="$HOME/.ssh/id_rsa"
#MOUNT_DIR=$(mktemp -d)


# Proxy connection settings
# ------------------------------------
# create master socket first: 
#
#     ssh -M -S /path/to/your-socket-file you@example.com -p 1234
#
SSH_SOCKET_FILE="/path/to/your-socket-file"
NODE_RENDEZVOUS_PORT=7000
