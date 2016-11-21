#!/bin/bash 


# ----------------------------------------------------
# -- Checklist
# ----------------------------------------------------
# * detect device to format
# * create appropriate partitions
# * format these partitions with appropriate filesystems
# * mount partitions
# * copy files from backup to these mountpoints
# * INSTALL APPROPRIATE BOOTLOADER (no need for RaspberryPi)
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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DEFAULT_DEVICE="/dev/mmcblk0"
BACKUP=$(readlink -f "${DIR}/../snapshots/backup.last-0")

clear 
echo "Backup to be restored: ${BACKUP} "
ls "${BACKUP}"
pause

read -a DEVICE -p "Device to be formatted (default: /dev/mmcblk0) : "
if [[ "${DEVICE}" == "" ]]; then 
	DEVICE=${DEFAULT_DEVICE}
fi

while true; do 

	if [[ "${DEVICE}" == "" ]]; then 
		# get correct device name
		echo "Look correctly"
		sleep 2
		echo "Plug/unplug the device"
		sleep 2
		echo "Get the device name (eg. /dev/mmcblk0)"
		sleep 2
		echo "Press Ctrl+C when you are done."		
		sleep 3
		watch "readlink -f /dev/disk/by-path/*"
		read -a DEVICE -p "Device to be formatted:"
	fi

	read -a OK_TO_GO -p "Device to format is $DEVICE. Is that correct? (yes/no)"
	if [[ "${OK_TO_GO}" == "yes" ]]; then
		break 
	else
		clear
		DEVICE=""
	fi

done

if [[ -b ${DEVICE} ]]; then 
	echo "Using device: ${DEVICE}"
	pause 
else
	echo "${DEVICE} does not exist..."
	exit 2 
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

echo "Creating partition table on ${DEVICE}..."
# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can 
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVICE}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +110M # boot parttion
  t # change the type (1st partition will be selected automatically)
  c # Changed type of partition 'Linux' to 'W95 FAT32 (LBA)', mandatory for RaspberryPi
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
mkfs.vfat ${BOOT_PART}
# ext4 filesystem is problematic on Raspbian Jessie, so 
# stick with ext3 for now
mkfs.ext3 ${ROOT_PART}

echo "Creating mountpoints: ${BOOT_MNT} and ${ROOT_MNT}"
mkdir ${BOOT_MNT}
mkdir ${ROOT_MNT}

echo "Mounting partitions..."
mount ${BOOT_PART} ${BOOT_MNT}
mount ${ROOT_PART} ${ROOT_MNT}

echo "Restoring files from backup... (${BACKUP})"
rsync  -aHAXvPh "${BACKUP}/boot/" ${BOOT_MNT}
rsync  -aHAXvPh --exclude "boot" "${BACKUP}/" ${ROOT_MNT}
mkdir "${ROOT_MNT}/boot"

echo "Syncing..."
sync

echo "unmounting devices.."
umount ${BOOT_PART}
umount ${ROOT_PART}

echo "Removing mountpoints..."
rmdir ${BOOT_MNT}
rmdir ${ROOT_MNT}

echo "Done..."
