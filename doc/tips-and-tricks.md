# Tips

Whenever you need to update tools, run update:

	make update

If you want to make it self-update on next run, remove the flag file:

	rm project-directory/up-to-date

If you want to run a remote command, simply pass via ARGS= parameter

    make ssh ARGS='uname -a'
    # or
    ./dcs-tools/ssh-proxy uname -a
    ./dcs-tools/ssh-direct uname -a

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
find . -maxdepth 2 -name "up-to-date" -exec rm {} \;
```

You can **force** all toolboxes update **immediately**:

```
cd remote-machines
find . -type d -maxdepth 1 -exec sh -c '(echo {}; cd {} && make update)' ';'
```
