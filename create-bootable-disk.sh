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

# exit on error
set -e

set_dir () { DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"; }
safe_source () { source $1; set_dir; }
set_dir

if [[ $(id -u) > 0 ]]; then
    #echo "This script needs root privileges..."
    sudo $0 "$@"
    exit
fi

safe_source $DIR/aktos-bash-lib/basic-functions.sh
safe_source $DIR/aktos-bash-lib/fs-functions.sh

backup=
device=
fstype=
verbose=0
skip_format=false

show_help () {
    cat <<HELP

    Usage:

        $(basename $0) ...options...

    Options:

    --backup        : backup directory
    --device        : the device to format and create bootable disk
    --fs-type       : target filesystem type (default ext3)
    --skip-format   : skip formatting target disk, only rsync.

HELP
}

while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        --backup)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                backup=$(realpath $2)
                shift
            else
                die '"--backup" requires a non-empty option argument.'
            fi
            ;;
        --device)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                device=$2
                shift
            else
                die '"--device" requires a non-empty option argument.'
            fi
            ;;
        --fs-type)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                fstype=$2
                shift
            else
                die '"--fs-type" requires a non-empty option argument.'
            fi
            ;;
        -v|--verbose)
            verbose=$((verbose + 1))  # Each -v adds 1 to verbosity.
            ;;
        --skip-format)
            skip_format=true
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

# check the arguments if they are valid
if [[ ! -d $backup ]]; then
    die "Backup directory must be provided! (not a dir: $backup)"
else
    echo_green "Using backup directory: $backup"
fi

if [[ ! -b $device ]]; then
    die "Bootable disk device must be provided"
else
    echo_green "Using device: $device"
fi

if [ "$fstype" ]; then
    echo_green "Using filesystem type: $fstype"
else
    fstype="ext3"
    echo_yellow "Using default $fstype type. "
fi

if [ $skip_format ]; then
    echo_yellow "...will skip formatting..."
fi

if prompt_yes_no "Should we really continue?"; then
    echo_yellow "Bootable device $device will be built by using $backup"
else
    echo_info "Interrupted by user."
    exit 0
fi
# end of check arguments 

# -----------------------------------------------------------------------------
#   All variables are set so far
# -----------------------------------------------------------------------------

# device partitions
BOOT_PART="${device}p1"
ROOT_PART="${device}p2"

require_device $BOOT_PART
require_device $ROOT_PART

umount_if_mounted $BOOT_PART
umount_if_mounted $ROOT_PART

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

echo "Mounting partitions..."
mount ${BOOT_PART} ${BOOT_MNT}
mount ${ROOT_PART} ${ROOT_MNT}

echo "Restoring files from backup... (${backup})"
rsync  -aHAXh "${backup}/boot/" ${BOOT_MNT}
rsync  -aHAXh --exclude "boot" "${backup}/" ${ROOT_MNT}
mkdir -p "${ROOT_MNT}/boot"

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
