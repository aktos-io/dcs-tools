# Working system `fdisk -l` output:
# -------------------------------
# Disk /dev/mmcblk0: 7.4 GiB, 7969177600 bytes, 15564800 sectors
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes
# Disklabel type: dos
# Disk identifier: 0x378fc799
#
# Device         Boot Start      End  Sectors  Size Id Type
# /dev/mmcblk0p1       8192 15253503 15245312  7.3G 83 Linux
#

echo_green "Formatting for Orange Pi"

ROOT_PART="${device}${FIRST_PARTITION}"
umount_if_mounted3 $ROOT_PART
exit

# mountpoints
BOOT_MNT="$(mktemp -d --suffix=-boot)"
ROOT_MNT="$(mktemp -d --suffix=-root)"
echo "Using mount points: "
echo "...Boot MNT: $BOOT_MNT"
echo "...Root MNT: $ROOT_MNT"

if [ ! $skip_format ]; then
    echo "Creating partition table on ${device}..."
    # to create the partitions programatically (rather than manually)
    # we're going to simulate the manual input to fdisk
    # The sed script strips off all the comments so that we can
    # document what we're doing in-line with the actual commands
    # Note that a blank line (commented as "default" will send a empty
    # line terminated with a newline to take the fdisk default.
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${device}
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
    mkfs.$fstype ${ROOT_PART}
fi

require_device $BOOT_PART
require_device $ROOT_PART

echo "Mounting partitions..."
mount ${BOOT_PART} ${BOOT_MNT}
mount ${ROOT_PART} ${ROOT_MNT}

echo "Restoring files from backup... (${backup})"
rsync  -aHAXh "${backup}/boot/" ${BOOT_MNT}
rsync  -aHAXh --exclude "boot" "${backup}/" ${ROOT_MNT}
mkdir -p "${ROOT_MNT}/boot"

echo "Setting /etc/resolv.conf attributes to make it immutable"
chattr +i $ROOT_MNT/etc/resolv.conf


echo "Syncing..."
sync

echo "unmounting devices.."
umount ${BOOT_PART}
umount ${ROOT_PART}

echo "Removing mountpoints..."
rmdir ${BOOT_MNT}
rmdir ${ROOT_MNT}

echo_yellow "Do not forget to check the following files on target: "
echo_yellow " * /boot/cmdline.txt"
echo_yellow " * /etc/fstab"
echo_yellow " * /etc/network/interfaces"

echo_green "Done..."
