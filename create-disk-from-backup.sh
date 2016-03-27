#!/bin/bash 


# Checklist
# ----------------------------------------------------
# detect which device to format
# create appropriate partitions
# format these partitions with appropriate filesystems
# mount partitions
# copy files from backup to these mountpoints
# INSTALL APPROPRIATE BOOTLOADER 
#

if [[ $(id -u) > 0 ]]; then 
    echo "This script needs root privileges..."
    sudo $0
    exit
fi 

pause () {
    read -p "Press enter to continue..."
}

debug_eval () {
    echo "$*"
    eval "$*"
}

# get correct device name
echo "Plug/unplug the device and get the correct device name..."
echo ""
echo "Press Ctrl+C when you are done."
###sleep 2

###watch "readlink -f /dev/disk/by-path/*"


###read -a DEVICE -p "Type the name of the device (eg. /dev/mmcblk0) : "

DEVICE="/dev/mmcblk0"
BACKUP="../snapshots/backup.last-0"

###read -a OK_TO_GO -p "Device to format is $DEVICE. Is that correct? (yes/no)"

# DEBUG
OK_TO_GO="yes"

if [[ "${OK_TO_GO}" != "yes" ]]; then
    echo "I'll give you some time to think about it..."
    exit
fi

# device partitions
BOOT_PART="${DEVICE}p1"
ROOT_PART="${DEVICE}p2"

MOUNT_POINT="/mnt/aktos-tmp"

# mountpoints
BOOT_MNT="${MOUNT_POINT}p1"
ROOT_MNT="${MOUNT_POINT}p2"

umount ${BOOT_PART} 2> /dev/null
umount ${ROOT_PART} 2> /dev/null

echo "Will create partition table on the disk..."
pause

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
#
# ----------------------------------
# WARNING: USE TABS FOR INDENTATION!
# ----------------------------------
#
sed -e 's/\t\([\+0-9a-zA-Z]*\)[ \t].*/\1/' << EOF | fdisk ${DEVICE}
	o # clear the in memory partition table
	n # new partition
	p # primary partition
	1 # partition number 1
	 # default - start at beginning of disk
	+100M # 100 MB boot parttion
	n # new partition
	p # primary partition
	2 # partion number 2
	 # default, start immediately after preceding partition
	 # default, extend partition to end of disk
	a # make a partition bootable
	1 # bootable partition is partition 1 -- /dev/sda1
	p # print the in-memory partition table
	w # write the partition table
	q # and we're done
EOF


echo "Creating filesystem on device partitions..."
pause
echo y | mkfs.ext2 ${BOOT_PART}
echo y | mkfs.ext4 ${ROOT_PART}

echo "Creating mountpoints..."
pause
mkdir ${BOOT_MNT}
mkdir ${ROOT_MNT}

echo "Mounting and syncing DEVICE/boot and DEVICE/root directories..."
pause
mount ${BOOT_PART} ${BOOT_MNT}
mount ${ROOT_PART} ${ROOT_MNT}


echo "Restoring files from backup... (${BACKUP})"
ls "${BACKUP}"
pause
rsync  -aHAXvPh "${BACKUP}/boot/" ${BOOT_MNT}
rsync  -aHAXvPh --exclude "boot" "${BACKUP}/" ${ROOT_MNT}


echo "Syncing..."
sync

echo "unmounting devices.."
pause
umount ${BOOT_PART}
umount ${ROOT_PART}

echo "Removing mountpoints..."
rmdir ${BOOT_MNT}
rmdir ${ROOT_MNT}

echo "Done..."
