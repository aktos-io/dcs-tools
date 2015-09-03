# aktos-dcs-tools 

This toolset is intended to use with remote Linux devices (embedded or not). 

Capabilities: 
* can connect with `ssh` over "SSH Rendezvous Server"
* can `ssh` directly 
* can `mount`/`umount` target device's root directory with `sshfs`
* can do incremental backups via `rsyc` and transfers only changed files and keeps versions.

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

	# select a session type (default: direct)
	make set-[direct, proxy, local]-session 

	# you have several action options: 
	make init               # only for the first run
	make mount-root         # mounts the root folder to NODE_ROOT 
	make ssh                # makes ssh 
	make backup-root        # backups whole root partition 
	
	# whenever you need to update tools, run update: 
	make update 
	
	# if you want to make it self-update on next run, remove the flag file: 
	rm project-directory/project-tools/no-need-to-update-flag
