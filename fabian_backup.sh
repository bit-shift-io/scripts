#!/bin/bash
#
# To setup your hard drive as a backup:
# 1) make a directory called backup on your backup drive, which should also be labelled 'backup' and mounted at: /run/media/server/backup
# 2) mkdir -p -- "/run/media/server/backup/backup" ; touch "/run/media/server/backup/backup/backup.marker"
# 3) then you can run this script to perform a backup

# if [ ! -d "/rsync-time-backup/" ]; then
#     echo "Downloading rsync-time-backup...."
#     git clone https://github.com/laurent22/rsync-time-backup
# fi


DEST_DIR_1="/run/media/server/offsite/fabian" # external hdd backup
#DEST_DIR_2="$HOME/Backups/Fabian/backup" # local backup

cd rsync-time-backup

# local backup - just uses rsync
#echo "Performing local backup up from '$HOME' to '$DEST_DIR_2'..."
#rsync -av $HOME/ $DEST_DIR_2 --exclude-from ../fabian_backup_excludes.txt

# external hdd backup - use rsync-time-backup
#if [ -d "$DIRECTORY" ]; then
    echo "Performing external backup up from '$HOME' to '$DEST_DIR_1'...."
    ./rsync_tmbackup.sh $HOME $DEST_DIR_1 ../fabian_backup_excludes.txt
    #./rsync_tmbackup.sh $HOME $DEST_DIR_2 ../fabian_backup_excludes.txt
#else
#    echo "Skipping external backup as '$DEST_DIR_1' does not exist."
#fi

echo "Backup complete."