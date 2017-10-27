# Configuration 

Terminology: 

* `NODE_*` or *target*: the target Linux system you want to manage from your host. 
* *RENDEZVOUS SERVER*: An intermediate server that will serve as a rendezvous point with you and your target. (see [proxy-connection.md](./proxy-connection.md))


## Custom SSH Key

Setup the custom SSH key that you will use for your passwordless logins:

```bash
KEY_FILE="/path/to/your/id_rsa"
```
 Default: `$HOME/.ssh/id_rsa`

## Proxy Connection

Add the following options to your configuration file:

    SSH_SOCKET_FILE="/path/to/your-socket-file"
    NODE_RENDEZVOUS_PORT=1234

You are responsible for creating an SSH connection beforehand to your Rendezvous server with a Master Socket File option: 

    ssh -M -S /path/to/your-socket-file you@example.com -p 1234

Then change the connection method once: 

    make proxy-connection 
    
    
You will be able to use rest of your daily usage commands as before: 

    make ssh
    make mount-root 
    ...


## Custom Mountpoint

To change the mount directory which the remote device's root (`/`) folder is mounted onto.

    MOUNT_DIR=/path/to/your-mount-dir

 Default is `/tmp/tmp.RANDOM`
