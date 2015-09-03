# aktos-dcs-tools 

This toolset is intended to use with remote Linux devices (embedded or not). You can:

* make ssh
* make mount-root of target pc
* make backup-root of target/local pc

easily. There are 3 modes available: 

* direct (connected remote via local area network or a direct cable)
* proxy (via a rendezvous server) 
* local (for making backups of localhost)

Backups are: 

* incremental (only differences are transmitted) 
* simple copies of original files (you can simply copy/paste when you need to restore)
* versioned (you may increase this number)
* small (if you backup your 10 GB root for 5 times, you end up using 10.2 GB disk space if you have no modified files. But you will see the `snapshots` folder has a size of 50 GB. (Magic? No: Hardlinks)

When making a backup, you can cancel at any point and resume later. All operations are resumable.

> Hint: You may use this toolset to take full incremental backups for your own computer: 
>    
>      make set-session-local 
>      make backup-root

# Install


	# move to your project/backup directory
	cd project-directory

	# clone (or download) repository
	git clone https://github.com/ceremcem/aktos-dcs-tools project-tools
	
	# optionally set current directory as project directory (recommended)
	ln -s project-tools/Makefile 

	# create and edit the configuration file
	./project-tools/configure
	
# Usage

	# select a session type (default: direct)
	make set-[direct, proxy, local]-session 

	# you have several action options: 
	make init               # only for the first run
	make mount-root         # mounts the root folder to NODE_ROOT 
	make ssh                # makes ssh 
	make backup-root        # backups whole root partition 
	
# Tips 

	# whenever you need to update tools, run update: 
	make update 
	
	# if you want to make it self-update on next run, remove the flag file: 
	rm project-directory/project-tools/no-need-to-update-flag
	
	# if you want to run a remote command, simply pass via ARGS= parameter
	make ssh ARGS='uname -a'
	
	# to create a Local port forward: 
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
 
you can force all toolboxes update themselves on next run by issuing the following command: 

```
cd remote-machines 
find . -maxdepth 3 -name "no-need-to-update*" -exec rm {} \;
```

you can force all toolboxes update immediately: 

```
cd remote-machines 
find . -type d -maxdepth 1 -exec sh -c '(echo {}; cd {} && make update)' ';'
```

