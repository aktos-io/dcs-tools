# Description

This toolset is intended to use for managing remote Linux devices (RaspberryPi in mind, but any remote Linux system will work) from host Linux systems, by basically simplifying 5 tasks if you need to:

1. make `ssh` for performing remote tasks (either directly or by a link up server)
2. use simple drag and drop style file transfers (by `sshfs`).
3. backup the target's entire root filesystem (by `rsync`).
4. create incremental backups.
5. create bootable system disks from any of your backups locally.
6. clone a target with a new identity

This simplification is achieved by:

 * Placing separate scripts for each task described above.
 * Keeping the scripts, configuration settings and backups are kept in a folder called `your-project`.

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

1. Create your configuration file and mandatory folders/flags:

       ./dcs-tools/setup

    > `NODE_IP=` the IP address of the target \
    > `NODE_PORT=` the SSHD port (normally 22) \
    > `NODE_USER=` username for login \
    > 
    > See [doc/configuration.md](./doc/configuration.md) for other options and explanations.

2. Set your connection type (see usage/1)

3. *(Optional)*: Send your RSA public key to the target in order to prevent asking password on every connection:

       ./dcs-tools/make-target-settings  

# Usage

### Set connection type

*either connect to your target by its direct IP address and port:*
```bash
make conn-direct
```
*or  meet with your target on a link up server* (see [link-with-server](https://github.com/aktos-io/link-with-server))
```bash
make conn-over-proxy
```

See [doc/configuration.md](./doc/configuration.md) for explanations.

### Make ssh

```bash
make ssh
```

Makes ssh connection either directly or via the link up server according to [your connection type](#set-connection-type).

### Mount target root

```bash
make mount-root
```
Mounts the root folder to `your-project/NODE_ROOT`, which you can use for drag-n-drop style file transfers.

You can later unmount with `make umount-root` without using `sudo` command.

### Sync target's root folder

```bash
make sync-root
```

Sync whole root partition of the target with `your-project/sync-root` folder. You can use this command consecutively to keep your `sync-root` folder up to date as much as possible. Only differentiating data will be transmitted (if any).

This command will only copy the current state of your target to your host machine. You will need to create your backups manually, with `make backup-sync-root` command

### Create backups       

```bash
make backup-sync-root
```

Create a backup from the `sync-root` folder into `./backups` folder either by hardlinks method or by creating a btrfs subvolume, according to your `your-project/method-*` flag. 

> `method-*` flags can be set by `make method-btrfs` or `make method-hardlinks` commands.


## Advanced actions:

Following tools are for advanced usage, use them **with extreme caution**.


### Produce bootable disk from a backup

```bash
./dcs-tools/produce-bootable-disk [--help]   
```

Produces a bootable disk that is capable of booting your target hardware.


### Restore files from a backup to physical disk

```bash
./dcs-tools/restore-from-backup [--help]
```     
Restores all files from backup folder to the SD card. Useful when you want to
update your physical backup disk with your latest sync folder.

### Convert to fresh install

```bash
./dcs-tools/convert-to-fresh-install [--help]
```

Modify a root folder (possibly a backup folder) in order to make it like a freshly installed target, by refreshing `etc/hostname`, `home/user/.ssh/...` etc.

## Recipes

### Cloning a target into a new target

1. Create your `new-target` folder with and initialize the dcs-tools:

       mkdir new-target
       cd new-target
       git clone --recursive https://github.com/aktos-io/dcs-tools
       ./dcs-tools/setup

2. Copy your `curr-target`'s backup folder:

       sudo cp -al /path/to/curr-target/sync-root .

3. Convert to a fresh install

       ./dcs-tools/convert-to-fresh-install --root-dir sync-root/ ...

4. Create a bootable disk

       ./dcs-tools/produce-bootable-disk --backup ./sync-root/ --device ...

5. Insert your bootable disk to your target device and power up. 


### See Also

[Helper methods](./doc/tips-and-tricks.md)


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
