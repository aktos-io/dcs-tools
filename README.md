# Description

This toolset is intended for administrating remote Linux devices that are directly connected or behind a proxy server (RaspberryPi in mind, but any remote Linux system will work), by simplifying 7 tasks:

1. `make ssh` to connect the remote shell (either directly or over a link up server).
2. Responsively edit remote files via local IDE almost independent from the internet connection speed and interruptions ("Responsive remote development").
3. Use simple drag and drop style file transfers (by `sshfs`).
4. Backup the target's entire root filesystem (by `rsync`).
5. Create fast and efficient **differential full backups** (by hardlinks or by BTRFS snapshots).
6. Create a separate physical bootable system disk from any of your backups.
7. Clone the current device with a new identity to create a new device.


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

2. *(Optional)*: Send your RSA public key to the target in order to prevent asking password on every connection:

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

### Responsive Remote Development

Responsive remote development means keeping a local folder in sync with a remote folder. 

1. `cp ./sync-config-example.sh path/to/your/project/folder/my-sync-config.sh`
2. Edit `my-sync-config.sh` accordingly. See `./sync-with-sgw.sh --help` for options.
3. Send your project folder to your remote system and watch for changes by: 

	    ./sync-with-sgw.sh -c path/to/your/project/folder/my-sync-config.sh --dry-run

This will keep `path/to/your/project/folder/` and `$dest_dir` (within your config file) in sync. Remove the `--dry-run` switch for real transfer if the transfer summary is as you expected. 

Synchronization will exclude the `.git` folder and the other files/folders listed in `path/to/your/project/folder/.gitignore`.

`run_before_sync` hooks can be used to build, bundle, copy files or perfom any other tasks before the actual synchronization. Synchronization will fail and display a visual error message if any of the hooks fails. 

### Mount target root

```bash
make mount-root
```
Mounts the root folder to `your-project/NODE_ROOT`, which you can use for drag-n-drop style file transfers.

You can later unmount with `make umount-root` without using `sudo` command. 

This feature is only practical with fast (generally on local) connections.

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


### UDP port forwarding 

> Taken from https://superuser.com/a/974091/187576

Example connection: 

```
[PLC 192.168.250.9 UDP/9600] <--> [Scada-Gateway (sgw)] <--> [Rendezvous server] <--> [Laptop] <--> [Virtual machine]
```

1. Assign the same IP of the PLC to your laptop: 

		sudo ip a add 192.168.250.9/24 dev wlp2s0

2. In terminal 1 on your laptop:

		laptop$ cd your/project
		laptop$ make ssh ARGS="-L 9602:localhost:9602"
		sgw$ socat -T10 TCP4-LISTEN:9602,fork UDP4:192.168.250.9:9600

3. In terminal 2 on your laptop: 

		laptop$ sudo socat UDP4-LISTEN:9600,fork TCP4:localhost:9602

4. In your virtual machine's network settings -> Bridged adapter -> wlp2s0


Result: Your virtual machine will not detect any difference and will connect the target PLC as if it is connected directly.


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

### Give New ID

Make appropriate changes to give new identity to an installation. Useful for creating
a new controller/machine based on current installation.

```bash
./dcs-tools/give-new-id [--help]
```

### See Also

* [Recipes](./doc/recipes.md)

* [Helper methods](./doc/tips-and-tricks.md)


# Advantages
Backups have following properties:

* **portable** (you can move your copies around. eg: take first backup locally, remove disk, mound on another computer, `make backup-root` again)
* **differential** (only differences are transmitted)
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

### Hardlinks are not always safe 

Hardlinks are simply pointers to a file in the filesystem. If you delete or overwrite a file, your hardlinks (thus your backups) are safe. However, if you open a file and change the contents, all hardlinks point to this new data. So your backups (your previous data) are instantly broken. If you don't use BTRFS-method, you should always update your files by overwriting, not updating their contents. 
