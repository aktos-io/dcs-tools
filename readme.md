# Install


Preferably create a project directroy per device:

```
cd project-directory
git clone https://github.com/ceremcem/aktos-dcs-tools project-tools
ln -s project-tools/Makefile . 
```

	./project-tools/configure
	# edit the configuration file

	# for options:
	make [TAB]


	# machine with link-with-server options: 
	make init-remote        # for the first run
	make mount-root         # mounts the root folder 
	make ssh 	        # makes ssh
	make backup-remote-root 

	# localhost options
	make init               # for the first run
	make backup-local-root  # backup this machine's root folder

 
	# direct options
	make init-direct
	make ssh-direct
	make backup-remote-root-direct
	make mount-root-direct
