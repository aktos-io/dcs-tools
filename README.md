# Description

This toolset is intended to use for managing remote Linux devices (RaspberryPi in mind, but any remote Linux system will work) from host Linux systems, by basically simplifying 5 tasks:

1. You use `ssh` for performing remote tasks.
2. You use `sshfs` for simple drag and drop style file transfers.
3. You use `rsync` for backing up of target's entire root filesystem.
4. You need to create incremental backups.
5. You need to create bootable system disks from any of your backups locally.

# Install

### Requirements

* Linux OS
* `git` (for submodule fetching and `make update`)
* `rsync`
* `sshfs`

### Setup

Follow these steps for every project:

	# on your host (eg. your laptop)
	mkdir your-project
	cd your-project
	git clone --recursive https://github.com/aktos-io/dcs-tools

### Configuration

Assuming you are in `/path/to/your-project` folder already, 

1. Create your `config.sh` and mandatory folders/flags: 

       ./dcs-tools/setup

    > For the simplest configuration, assuming your target has the IP of `192.168.1.6`:
    > 
    >     NODE_IP="192.168.1.6"
    >     NODE_USER="aea"
    >     NODE_PORT=22

2. Select the connection type:

       # either:
       make conn-direct          # connect to remote target its IP address and port
       
       # or:
       make conn-over-proxy      # meet with your target on a known server


3. *(Optional)*: Send your RSA public key to the target in order to prevent asking password on every connection:

       ./dcs-tools/make-target-settings  

See [doc/configuration.md](./doc/configuration.md) for explanations.

### Usage

```bash
make ssh                # makes ssh
make mount-root         # mounts the root folder to `your-project/NODE_ROOT`, later unmount with `make umount-root`
make sync-root          # sync whole root partition of target with `your-project/sync-root` folder
make backup-sync        # make a backup from the sync-root folder
```

##### Advanced actions:

Following tools are for advanced usage, use them with caution:

```bash
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

If you are not using **btrfs**, "dead simple copies" feature has a problem by its design: As backups are just plain folders, this may lead breaking (unintentionally changing) the ownership of the files if you move/copy your files carelessly (eg. if you `mv your/snapshot to/another/location` and then interrupt the command in the middle, you will probably end up with moved files having `root:root` permissions.) That's why you **SHOULD always use `rsync`** for such movements.

> If you are using `--method btrfs`, backups are made as readonly snapshots, so you will not have such problems.

### Use correct filesystem

Make sure that you are performing `make sync-root` command on a native Linux
filesystem. You will end up having a backup with wrong file ownership and/or
permissions otherwise.

# See Also

[Tips and tricks](./doc/tips-and-tricks.md)
