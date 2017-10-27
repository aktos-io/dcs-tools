# Description

This toolset is intended to use for managing remote Linux devices (embedded or not) from host Linux systems. 

# Install

### Requirements 

* Linux OS
* `git` (for submodule fetching and `make update`)
* `rsync`

### Setup 

Follow these steps for every project:

	# on your host (eg. your laptop)
	mkdir your-project
	cd your-project
	git clone https://github.com/aktos-io/dcs-tools
	cd dcs-tools 
	git submodule update --init --recursive 
	./setup 

### Configuration 

Terminology: 

* `NODE_*` or *target*: the target Linux system you want to manage from your host. 
* `KEY_FILE`: the SSH key file you will use for passwordless login
* `SSH_SOCKET_FILE`: the socket file for re-using an existing ssh connection (to greatly improve the performance)
* *RENDEZVOUS SERVER*: An intermediate server that will serve as a rendezvous point with you and your target. (see [doc/proxy-connection.md](./doc/proxy-connection.md))


### Usage

1. First, you should prepare your target in order to `make ssh` and `make sync-root` without password:
	    
        ./dcs-tools/make-target-settings

2. Daily usage: 

```bash
cd your-project
```
	    
REQUIRED: setup a connection type for the first time

```bash
make direct-connection  # connect to remote target directly (LAN, Internet, directly via cable)
# or 
make proxy-connection   # connect to remote target via a rendezvous server
```

Options/actions: 

```bash
make ssh                # makes ssh
make mount-root         # mounts the root folder to NODE_ROOT
make umount-root        # unmount the root folder from NODE_ROOT
make sync-root          # sync whole root partition of target
```

Advanced actions:

```bash
./dcs-tools/make-backup              # from synchronized folder
./dcs-tools/produce-bootable-disk    # from any backup folder
./dcs-tools/restore-from-backup      # restores all files from backup folder to SD card
```

### Connection types

There are 2 connection modes available:

* `make direct-connection` : connected to remote target directly (LAN, Internet, directly via cable)
* `make proxy-connection`  : connected to remote target via a rendezvous server

# Advantages
Backups have following properties:

* **portable** (you can move your copies around. eg: take first backup locally, remove disk, mound on another computer, `make backup-root` again)
* **incremental** (only differences are transmitted)
* **dead simple copies** of original files (you can simply copy/paste when you need to restore or move your files around) **(see BIG WARNING)**
* **versioned** : Take any number of full backups as much as you like. You are responsible for deleting old backups.
* **efficient storage usage** (if you backup your 10 GB root for 5 times, you end up using 10.2 GB disk space if you have no modified files. But you will see the `snapshots` folder has a size of 50 GB. (Magic? No: Hardlinks or BTRFS subvolumes)

# BIG WARNING

### Move your backups around carefully

If you are not using **btrfs**, "dead simple copies" feature will bite you in the following way:
 
Backups are just plain folders, which may lead breaking (unintentionally changing) the ownership of the files if you move/copy your files carelessly (eg. if you `mv your/snapshot to/another/location` and then interrupt the command in the middle, you will probably end up with moved files having `root:root` permissions.) That's why you **SHOULD always use `rsync`**.

If you are using `--method btrfs`, backups are made as readonly snapshots. 

### Use correct filesystem

Make sure that you are performing `make sync-root` command on a native Linux
filesystem. You will end up having a backup with wrong file ownership and/or
permissions otherwise.
	
# See Also 

[Tips and tricks](./doc/tips-and-tricks.md)

# Complementary Libraries 

* [link-with-server](https://github.com/aktos-io/link-with-server/) : Reliably put target node's SSH port into server, make `make ssh` and `make mount-root` commands lightning-fast. 

