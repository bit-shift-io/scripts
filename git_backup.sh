#!/bin/bash

# ensure you have appropriate ssh key added to gitlab and github
#
# gitlab:
# generate a key on the server with:
#   ssh-keygen -t ed25519 -C "comment here"
#   cat ~/.ssh/id_ed25519.pub
#
# paste results into gitlab account > settings > ssh keys
#
# github:
#   cd ~/.ssh/ && ssh-keygen -t rsa -b 4096 -C "email@example.com"
#   cat id_rsa.pub
#
# paste result into github account > SSH and GPG keys > New SSH key

BACKUP_DIR=~/Projects
GITLAB="git@gitlab.com:bit-shift-io"
GITHUB="git@github.com:bit-shift-io"

function git_backup {
    DIR="$BACKUP_DIR/$2"
    REPO_URL="$1/$2.git"
    #echo $DIR
    echo ""
    if [ ! -d "$DIR" ] 
    then
        echo "Backing up $REPO_URL. Cloning..."
        cd $BACKUP_DIR
        git clone "$REPO_URL"
    else
        echo "Backing up $REPO_URL. Fetching..."
        cd $DIR
        git fetch --all
    fi

    # https://stackoverflow.com/questions/10312521/how-to-fetch-all-git-branches
    cd $DIR
    for remote in `git branch -r`; do git branch --track ${remote#origin/} $remote; done
    git fetch --all
}

mkdir $BACKUP_DIR
git_backup $GITLAB "trains-and-things"
git_backup $GITLAB "misc"


git_backup $GITHUB "scripts"
git_backup $GITHUB "macrokey"
git_backup $GITHUB "qweather"
git_backup $GITHUB "audiobook"
git_backup $GITHUB "the-great-cook-up"
git_backup $GITHUB "bible-survey"
git_backup $GITHUB "fabtab"
git_backup $GITHUB "bitshift"
git_backup $GITHUB "rapel"
git_backup $GITHUB "project-wilko"
git_backup $GITHUB "machine-learning-experiments"
git_backup $GITHUB "airstream"
git_backup $GITHUB "tower-of-cards"
git_backup $GITHUB "qcalendar"
git_backup $GITHUB "flow"

git_backup $GITLAB "dog-fight"

echo ""
echo "Backup complete!"
echo ""
