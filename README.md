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

# Goals
Backups have following properties: 

* **portable** (you can move your copies around. eg: take first backup locally, remove disk, mound on another computer, `make backup-root` again) 
* **incremental** (only differences are transmitted) 
* **dead simple copies** of original files (you can simply copy/paste when you need to restore or move your files around)
* **versioned** (you may increase number of versions as you wish, default history is 5 versions backwards)
* **efficient storage usage** (if you backup your 10 GB root for 5 times, you end up using 10.2 GB disk space if you have no modified files. But you will see the `snapshots` folder has a size of 50 GB. (Magic? No: Hardlinks)

When making a backup, you can cancel at any point and resume later. All operations (including folder rotations) are resumable.

> Hint: You may use this toolset to take full incremental backups for your own computer: 
>    
>      make set-session-local 
>      make init 
>      make backup-root


> Note: Make sure that you are performing `make backup-root` commands on a native Linux filesystem. 

# Install

Follow these steps for a quick startup: 

	cd project-directory
	git clone https://github.com/aktos-io/aktos-dcs-tools
	./aktos-dcs-tools/configure
	
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

