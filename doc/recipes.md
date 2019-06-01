### Cloning a target into a new target

1. Create your `new-target` folder with and initialize the dcs-tools:

       mkdir new-target
       cd new-target
       git clone --recursive https://github.com/aktos-io/dcs-tools
       ./dcs-tools/setup

2. Copy your `curr-target`'s backup folder:

       sudo cp -al /path/to/curr-target/sync-root .

3. Give a new ID: 

       ./dcs-tools/give-new-id --root-dir sync-root/ ...

4. Create a bootable disk

       ./dcs-tools/produce-bootable-disk --backup ./sync-root/ --device ...

5. Insert your bootable disk to your target device and power up.

