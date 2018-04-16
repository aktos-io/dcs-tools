# Working system's disk's `fdisk -l` output:
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

# mountpoints
ROOT_MNT="$(mktemp -d --suffix=-root)"
echo "Using mount point: $ROOT_MNT"

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
      8192 # start definitely from this sector
        # default, extend partition to end of disk
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
EOF

    echo "Creating filesystem on device partitions..."
    echo_green "...creating $fstype for ROOT_PART ($ROOT_PART)"
    mkfs.$fstype ${ROOT_PART}
fi

require_device $ROOT_PART

echo "Mounting partitions..."
mount ${ROOT_PART} ${ROOT_MNT}

echo "Restoring files from backup... (${backup})"
rsync  -aHAXh "${backup}/" ${ROOT_MNT}

echo "Setting /etc/resolv.conf attributes to make it immutable"
chattr +i $ROOT_MNT/etc/resolv.conf

echo "Syncing..."
sync

echo "unmounting devices.."
umount ${ROOT_PART}

echo "Removing mountpoints..."
rmdir ${ROOT_MNT}

echo_yellow "Do not forget to check the following files on target: "
echo_yellow " * /etc/fstab"
echo_yellow " * /etc/network/interfaces"
