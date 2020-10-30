#!/bin/bash

# ensure you have appropriate ssh key added to gitlab
# generate a key on the server with:
#   ssh-keygen -t ed25519 -C "fab server"
#   cat /home/server/.ssh/id_ed25519.pub
#
# paste results into gitlab account > settings > ssh keys

BACKUP_DIR=~/Projects
GITLAB_URL="git@gitlab.com:bit-shift-io"

function gitlab_backup {
    DIR="$BACKUP_DIR/$1"
    REPO_URL="$GITLAB_URL/$1.git"
    echo "Backing up $REPO_URL"
    if [ ! -d "$DIR" ] 
    then
        cd $BACKUP_DIR
        git clone "$REPO_URL"
    else
        cd $DIR
        git fetch --all
    fi
}

mkdir $BACKUP_DIR
gitlab_backup "bitshift-www"
gitlab_backup "trains-and-things"
gitlab_backup "dog-fight"
gitlab_backup "misc"
gitlab_backup "shop"