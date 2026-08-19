#!/bin/bash
set -euo pipefail

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

BACKUP_DIR="$HOME/Projects"
GITLAB="git@gitlab.com:bit-shift-io"
GITHUB="git@github.com:bit-shift-io"

function git_backup {
    local dir="$BACKUP_DIR/$2"
    local repo_url="$1/$2.git"
    echo ""
    if [[ ! -d "$dir" ]]; then
        echo "Backing up $repo_url. Cloning..."
        cd "$BACKUP_DIR"
        git clone "$repo_url"
    else
        echo "Backing up $repo_url. Fetching..."
        cd "$dir"
        git fetch --all
    fi

    # https://stackoverflow.com/questions/10312521/how-to-fetch-all-git-branches
    cd "$dir"
    for remote in $(git branch -r); do
        git branch --track "${remote#origin/}" "$remote" || true
    done
    git fetch --all
}

mkdir -p "$BACKUP_DIR"
git_backup "$GITLAB" "trains-and-things"
git_backup "$GITLAB" "misc"

git_backup "$GITHUB" "scripts"
git_backup "$GITHUB" "macrokey"
git_backup "$GITHUB" "qweather"
git_backup "$GITHUB" "audiobook"
git_backup "$GITHUB" "the-great-cook-up"
git_backup "$GITHUB" "bible-survey"
git_backup "$GITHUB" "fabtab"
git_backup "$GITHUB" "bitshift"
git_backup "$GITHUB" "rapel"
git_backup "$GITHUB" "project-wilko"
git_backup "$GITHUB" "machine-learning-experiments"
git_backup "$GITHUB" "airstream"
git_backup "$GITHUB" "tower-of-cards"
git_backup "$GITHUB" "qcalendar"
git_backup "$GITHUB" "flow"
git_backup "$GITHUB" "fido-and-kitch"
git_backup "$GITHUB" "fido-and-kitch-assets"

git_backup "$GITLAB" "dog-fight"

echo ""
echo "Backup complete!"
echo ""