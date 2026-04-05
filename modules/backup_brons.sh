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
    i) install rclone

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_min ;;
        2) fn_full ;;
        i) fn_install ;;
        *) $SHELL ;;
    esac
    done
}

function fn_install {
    # install rclone
    ./util.sh -i rclone
}

function fn_min {
    ls /mnt/
    echo "Which drive to backup to (eg: offsite) : "
    read drive

    DEST_DIR_1="/run/media/bronson/${drive}/backups/bronson" # external hdd backup
    #DEST_DIR_1="/mnt/${drive}/backups/bronson" # external hdd backup

    #SRC_DIR_1="s@living.lan:/home/s"
    # echo "Start backup up from '$SRC_DIR_1' to '$DEST_DIR_1'...."
    # RSYNC_OPTS=(-va --exclude=".*" --delete)
    #rsync "${RSYNC_OPTS[@]}" $SRC_DIR_1/Bronson $DEST_DIR_1
    #rsync "${RSYNC_OPTS[@]}" $SRC_DIR_1/Haoying $DEST_DIR_1
    #rsync "${RSYNC_OPTS[@]}" $SRC_DIR_1/Misc $DEST_DIR_1
    #rsync "${RSYNC_OPTS[@]}" $SRC_DIR_1/Photos $DEST_DIR_1

    SRC_DIR_1=":sftp,host=living.lan,user=s,use_ssh_agent=false,key_file=~/.ssh/id_rsa:/home/s"
    echo "Start backup up from '$SRC_DIR_1' to '$DEST_DIR_1'...."
    RCLONE_OPTS=(--exclude ".*" --exclude ".*/**" -vP --fast-list --transfers 4 --checkers 8 --delete-excluded)
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Bronson" "$DEST_DIR_1/Bronson"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Haoying" "$DEST_DIR_1/Haoying"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Misc" "$DEST_DIR_1/Misc"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Photos" "$DEST_DIR_1/Photos"

    echo "Backup complete."
}

function fn_full {
    ls /mnt/
    echo "Which drive to backup to (eg: offsite) : "
    read drive

    DEST_DIR_1="/run/media/bronson/${drive}/backups/bronson" # external hdd backup
    SRC_DIR_1=":sftp,host=living.lan,user=s,use_ssh_agent=false,key_file=~/.ssh/id_rsa:/home/s"
    echo "Start backup up from '$SRC_DIR_1' to '$DEST_DIR_1'...."

    RCLONE_OPTS=(--exclude ".*" --exclude ".*/**" -vP --fast-list --transfers 4 --checkers 8 --delete-excluded)

    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Bronson" "$DEST_DIR_1/Bronson"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Haoying" "$DEST_DIR_1/Haoying"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Misc" "$DEST_DIR_1/Misc"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Photos" "$DEST_DIR_1/Photos"

    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Audiobooks" "$DEST_DIR_1/Audiobooks"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Bible" "$DEST_DIR_1/Bible"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Music" "$DEST_DIR_1/Music"
    rclone sync "${RCLONE_OPTS[@]}" "$SRC_DIR_1/Videos" "$DEST_DIR_1/Videos"

    echo "Backup complete."
}

# pass all args
main "$@"
