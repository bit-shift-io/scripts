#!/bin/bash

DEST_DIR_1="/mnt/offsite/backups/bronson" # external hdd backup
SRC_DIR_1="s@living.lan:/home/s"

echo "Start backup up from '$SRC_DIR_1' to '$DEST_DIR_1'...."

rsync -va $SRC_DIR_1/Bronson $DEST_DIR_1 --exclude=".*" --delete
rsync -va $SRC_DIR_1/Haoying $DEST_DIR_1 --exclude=".*" --delete
rsync -va $SRC_DIR_1/Misc $DEST_DIR_1 --exclude=".*" --delete
rsync -va $SRC_DIR_1/Photos $DEST_DIR_1 --exclude=".*" --delete

echo "Backup complete."
