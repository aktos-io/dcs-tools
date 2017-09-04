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
