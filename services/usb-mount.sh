#!/bin/bash

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"
MOUNT_DIR="/mnt"

# See if this drive is already mounted
MOUNT_POINT=$(/bin/mount | /bin/grep ${DEVICE} | /usr/bin/awk '{ print $3 }')

do_mount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        # Already mounted, exit
        exit 1
    fi
	
    # Get info for this drive: $ID_FS_LABEL, $ID_FS_UUID, and $ID_FS_TYPE
    eval $(/sbin/blkid -o udev ${DEVICE})

    # Figure out a mount point to use
    LABEL=${ID_FS_LABEL}
    if [[ -z "${LABEL}" ]]; then
        LABEL=${DEVBASE}
    elif /bin/grep -q " ${MOUNT_DIR}/${LABEL} " /etc/mtab; then
        # Already in use, make a unique one
        LABEL+="-${DEVBASE}"
    fi
    
    # create dir
    MOUNT_POINT="${MOUNT_DIR}/${LABEL}"
    /bin/mkdir -p ${MOUNT_POINT}
    
    # Global mount options
    # see fstab settings for what can be used here
    OPTS="defaults"
  
    # File system mount options:
    
    # vat = fat32
    if [[ ${ID_FS_TYPE} == "vfat" ]]; then
        OPTS+=",uid=1000,gid=1000"
        #OPTS+=",users,uid=1000,gid=1000,umask=000,shortname=mixed,utf8=1,flush"
    fi
    
    # exfat
    if [[ ${ID_FS_TYPE} == "exfat" ]]; then
        OPTS+=",uid=1000,gid=1000"
    fi
    
    # ext4
    sudo chmod 777 ${MOUNT_POINT}
    
    
    # remove dir on error
    if ! /bin/mount -o ${OPTS} ${DEVICE} ${MOUNT_POINT}; then
        /bin/rmdir ${MOUNT_POINT}
        exit 1
    fi
	
    # send desktop notification to user
    # sudo -u 1000 DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "Device ${DEVICE} mounted at ${MOUNT_POINT}"
}

do_unmount()
{
    if [[ -n ${MOUNT_POINT} ]]; then
        /bin/umount -l ${DEVICE}
    fi

    # Delete all empty dirs in /mount_dir that aren't being used as mount points. 
    for f in ${MOUNT_DIR}/* ; do
        if [[ -n $(/usr/bin/find "$f" -maxdepth 0 -type d -empty) ]]; then
            if ! /bin/grep -q " $f " /etc/mtab; then
                /bin/rmdir "$f"
            fi
        fi
    done
}
case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
esac
