#!/bin/bash


function main {
    # loop args
    if [[ $# -ne 0 ]] ; then
        for var in "$@" ; do
            eval $var
        done
        exit 1
    fi
    
    # menu
    while true; do
    read -n 1 -p "
    backup
    ===================
    1) Minimal
    2) Full

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_min ;;
        2) fn_full ;;
        *) $SHELL ;;
    esac
    done
}

function fn_min {
    ls /mnt/
    echo "Which drive to backup to (eg: offsite) : "
    read drive

    DEST_DIR_1="/run/media/bronson/${drive}/backups/bronson" # external hdd backup
    #DEST_DIR_1="/mnt/${drive}/backups/bronson" # external hdd backup
    SRC_DIR_1="s@living.lan:/home/s"

    echo "Start backup up from '$SRC_DIR_1' to '$DEST_DIR_1'...."

    rsync -va $SRC_DIR_1/Bronson $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Haoying $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Misc $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Photos $DEST_DIR_1 --exclude=".*" --delete

    echo "Backup complete."
}

function fn_full {
    ls /mnt/
    echo "Which drive to backup to (eg: offsite) : "
    read drive

    DEST_DIR_1="/mnt/${drive}/backups/bronson" # external hdd backup
    SRC_DIR_1="s@living.lan:/home/s"

    echo "Start backup up from '$SRC_DIR_1' to '$DEST_DIR_1'...."

    rsync -va $SRC_DIR_1/Bronson $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Haoying $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Misc $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Emulators $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Photos $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Audiobooks $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Backups $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Bible $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Music $DEST_DIR_1 --exclude=".*" --delete
    rsync -va $SRC_DIR_1/Videos $DEST_DIR_1 --exclude=".*" --delete

    echo "Backup complete."
}

# pass all args
main "$@"
