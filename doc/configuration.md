# Configuration 

Terminology: 

* `NODE` or the *target* is the target Linux system you want to connect/manage from your host. 
* Host: The computer you use to manage your NODE's, eg. your laptop.

Since the `config.sh` is sourced, you can use any `bash` commands to generate the variables.

## Direct Connection 

Command: `make direct-connection`

Used for direct connections that you would make if your target is on your LAN, on a outside network that you know its public IP, or connected with a direct LAN cable:

    NODE_IP="xx.yy.zz.tt"
    NODE_USER="aea"
    NODE_PORT=22


## Proxy Connection

Command: `make proxy-connection`

Proxy connection is a connection method that hides all details from you and lets you to meet with your target on a known server. See [proxy-connection.md](./proxy-connection.md) for details.

Make the following settings if you want to `make proxy-connection`s: 

1. Add the following options to your configuration file:

        SSH_SOCKET_FILE="/path/to/your-socket-file"
        NODE_RENDEZVOUS_PORT=1234


2. You are responsible for creating an SSH connection beforehand to your Rendezvous server with a Master Socket File option: 

        ssh -M -S /path/to/your-socket-file you@example.com -p 1234
    
 > Tip: use https://github.com/aktos-io/link-with-server/ on your host to create this connection automatically on every boot.


3. Then change the connection method once: 

        make proxy-connection     
    
    
You will be able to use rest of your daily usage commands as if you are connecting directly: 

    make ssh
    make mount-root 
    ...


## Custom SSH Key

Setup the custom SSH key that you will use for your passwordless logins:

    KEY_FILE="/path/to/your/id_rsa"

Default: `$HOME/.ssh/id_rsa`

## Custom Mountpoint

To change the mount directory which the remote device's root (`/`) folder is mounted onto:

    MOUNT_DIR=/path/to/your-mount-dir

Default is `/tmp/tmp.RANDOM`
