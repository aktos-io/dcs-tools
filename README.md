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

Simplest configuration, assuming your target has the IP of `192.168.1.6`: 

	NODE_IP="192.168.1.6" 
	NODE_USER="aea"
	NODE_PORT=22

For other options, see [configuration.md](./doc/configuration.md).

### Usage

First, you should prepare your target and setup your preferences:

	# assuming you are already in /path/to/your-project 
	./dcs-tools/make-target-settings  # optional, a password will be asked on every connection otherwise.
    
    # Setup the connection type for the first time 
	make direct-connection  # connect to remote target when you know its IP address and port
	# or meet with your target on a known server:
	make proxy-connection   # see doc/configuration.md
	
Options/actions: 

```bash
make ssh                # makes ssh
make mount-root         # mounts the root folder to `your-project/NODE_ROOT`, later unmount with `make umount-root`
make sync-root          # sync whole root partition of target with `your-project/sync-root` folder
```

Advanced actions:

```bash
./dcs-tools/make-backup              # make a backup from synchronized folder
./dcs-tools/produce-bootable-disk    # produce a bootable disk from any backup folder
./dcs-tools/restore-from-backup      # restores all files from backup folder to SD card
```

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
