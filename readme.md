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

Preferably create a project directroy per device:

```
cd project-directory
git clone https://github.com/ceremcem/aktos-dcs-tools project-tools
ln -s project-tools/Makefile . 
```

	./project-tools/configure
	# edit the configuration file

	# select a session type (default: direct)
	make set-[direct, proxy, local]-session 

	# you have several action options: 
	make init               # only for the first run
	make mount-root         # mounts the root folder to NODE_ROOT 
	make ssh                # makes ssh 
	make backup-root        # backups whole root partition 
