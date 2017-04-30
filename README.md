# Options

This toolset is intended to use with remote Linux devices (embedded or not). You can easily:

* `make ssh`
* `make ssh ARGS='-L 8080:localhost:1234'` # port forward or remote code execution
* `make mount-root` of target pc
* `make backup-root` of target/local pc
* `make create-disk-from-last-backup`

# Connection types

There are 3 connection modes available: 

* direct (connected remote via local area network or a direct cable)
* proxy (via a rendezvous server) 
* local (for making backups of localhost)

# Advantages
Backups have following properties: 

* **portable** (you can move your copies around. eg: take first backup locally, remove disk, mound on another computer, `make backup-root` again) 
* **incremental** (only differences are transmitted) 
* **dead simple copies** of original files (you can simply copy/paste when you need to restore or move your files around) (this is also a **disadvantage, see below**)
* **versioned** (you may increase number of versions as you wish, default history is 5 versions backwards)
* **efficient storage usage** (if you backup your 10 GB root for 5 times, you end up using 10.2 GB disk space if you have no modified files. But you will see the `snapshots` folder has a size of 50 GB. (Magic? No: Hardlinks)

When making a backup, you can cancel at any point and resume later. All operations (including folder rotations) are resumable.

> Hint: You may use this toolset to take full incremental backups for your own computer: 
>    
>      make set-session-local 
>      make init 
>      make backup-root

# Disadvantages

* Creating hardlinks for a 800GB backup may take hours
* `rsync` process may consume lots of CPU and IO resources, so your desktop becomes less usable during backup (your browser may start glitching while playing videos from web)
* backups are just plain folders, which may lead breaking (unintentionally changing) the ownership of the files if you move/copy your files carelessly (eg. if you `mv your/snapshot to/another/location` and then interrupt the command in the middle, you will probably end up with moved files having `root:root` permissions.  

# Install

Follow these steps for a quick startup: 

	cd project-directory
	git clone https://github.com/aktos-io/aktos-dcs-tools
	./aktos-dcs-tools/configure
	
# Configuration 

>Local: Your computer. 
>Node: Target Linux system in the field. 
>Rendezvous server: The SSH server which has a public IP address that you use to get to the node's SSHD server. 

Configuration options are as follows: 

* `TARGET_SSHD_PORT` : SSHD port that the `node` has put on rendezvous server. 
* `SSH_KEY_FILE` : Path to your ssh key file ([generate one](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/) if you don't have)
* `SERVER_USERNAME` : Your username at Rendezvous server
* `MOUNT_DIR` : Mount directory definition that will be used when you `make mount-root`
* `NODE_USERNAME` : Username on node 
* `NODE_LOCAL_IP` : Node's local IP address that will be used to connect to when you `make set-direct-session`
* `NODE_LOCAL_SSHD_PORT` : Node's local SSHD port (used when `make set-direct-session`)
* `RENDEZVOUS_HOST` : Rendezvous host's ip address (or domain name)
* `RENDEZVOUS_PORT` : Rendezvous host's SSHD port

### BIG WARNING

Make sure that you are performing `make backup-root` commands on a native Linux filesystem. 

# Example Usage

	# REQUIRED: select a session type (default: direct)
	make set-[direct, proxy, local]-session 

	# REQUIRED: Run when switching to a session type for the first time 
	make init
	
	# OPTIONS: you have several action options: 
	make mount-root         # mounts the root folder to NODE_ROOT
	make umount-root        # unmount the root folder from NODE_ROOT 
	make ssh                # makes ssh 
	make backup-root        # backups whole root partition 
	
# Tips 

Whenever you need to update tools, run update: 
	
	make update 
	
If you want to make it self-update on next run, remove the flag file: 
	
	rm project-directory/project-tools/no-need-to-update-flag
	
If you want to run a remote command, simply pass via ARGS= parameter
	
	make ssh ARGS='uname -a'
	
To create a Local port forward: 
	
	make ssh ARGS='-L 1234:localhost:5678'
	
# Advanced Tips

If you keep your directory layout like: 

+ remote-machines
  + machine-1
    + project-tools
    + Makefile
    + snapshots
    + ...
  + machine-2
    + aktos-dcs-tools (or whatever you named it)
    + Makefile
    + snapshots
    + ...
  + ...
 
You can **force** all toolboxes update themselves **on next run** by issuing the following command: 

```
cd remote-machines 
find . -maxdepth 3 -name "no-need-to-update*" -exec rm {} \;
```

You can **force** all toolboxes update **immediately**: 

```
cd remote-machines 
find . -type d -maxdepth 1 -exec sh -c '(echo {}; cd {} && make update)' ';'
```

