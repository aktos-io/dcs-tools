# Configuration 

## Custom ssh_key

```bash
KEY_FILE="/path/to/your/id_rsa"
```
 Default: `$HOME/.ssh/id_rsa`

## `make proxy-connection` related 

First, create an SSH connection to your Rendezvous server with a Master Socket File option: 

```bash
ssh -M -S /path/to/your-socket-file you@example.com -p 1234
```

Then add the following options to your configuration file:

```bash 
SSH_SOCKET_FILE="/path/to/your-socket-file"
NODE_RENDEZVOUS_PORT=1234
```

## `make mount-root` related

The directory to mount remote device's root (`/`) folder to.

```bash
MOUNT_DIR=/path/to/your-mount-dir
```

 Default is `/tmp/tmp.RANDOM`
