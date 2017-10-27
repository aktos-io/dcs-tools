# Configuration 

Terminology: 

* `NODE_*` or *target*: the target Linux system you want to manage from your host. 
* *RENDEZVOUS SERVER*: An intermediate server that will serve as a rendezvous point with you and your target. (see [proxy-connection.md](./proxy-connection.md))


## Custom ssh_key

The SSH key file you will use for passwordless login

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
