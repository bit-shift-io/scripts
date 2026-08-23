#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
source "$(dirname "${BASH_SOURCE[0]}")/mount_sshfs.sh"

# fedora cache: one shared dnf download cache for the whole LAN.
# python3-dnf-plugin-local saves every downloaded rpm into repodir and
# serves it as a repo, so only the first machine fetches each package
# from the internet, everyone else gets it over the LAN.
# https://blog.holtzweb.com/posts/fedora-repository-local-mirror-over-LAN/

# where the shared repo lives (sftp share gets mounted here)
MOUNT_POINT="/srv/fedoraLocalRepo"
SFTP_PATH="/home/dietpi/fedora"

echo "Enter sftp user:"
read -r SFTP_USER

echo "Enter sftp host eg media.lan:"
read -r SFTP_HOST

# ensure the ssh key the mount uses exists and is authorised on the remote box
# (only asks for the password if the key isn't authorised yet)
ensure_ssh_key "$SFTP_USER@$SFTP_HOST"

"$UTIL" -i python3-dnf-plugin-local

sudo mkdir -p "$MOUNT_POINT"

# reuse the sshfs module to create the mount + automount units
add_mount "$MOUNT_POINT" "$SFTP_USER" "$SFTP_HOST" "$SFTP_PATH"

# trigger the automount and wait for the real sshfs mount (not the autofs stub)
ls "$MOUNT_POINT" > /dev/null 2>&1 || true
path_name="${MOUNT_POINT#/}"
path_name="${path_name//\//-}"
mounted=false
for _ in {1..15}; do
    if findmnt -n -t fuse.sshfs "$MOUNT_POINT" > /dev/null; then
        mounted=true
        break
    fi
    sleep 2
done
if [[ "$mounted" != true ]]; then
    echo "mount failed: $MOUNT_POINT"
    journalctl -u "$path_name.mount" --no-pager -n 5 || true
    exit 1
fi

# initialise the repo metadata once (the plugin keeps it updated after that)
if [[ ! -d "$MOUNT_POINT/repodata" ]]; then
    "$UTIL" -i createrepo_c
    sudo createrepo_c "$MOUNT_POINT"
fi

# point the dnf local plugin at the share
sudo tee /etc/dnf/plugins/local.conf > /dev/null << EOL
[main]
enabled = true
# Path to the local repository.
repodir = $MOUNT_POINT
EOL

echo "fedora cache ready: $MOUNT_POINT -> $SFTP_USER@$SFTP_HOST:$SFTP_PATH"
echo "test it with: sudo rm -rf /var/cache/dnf && sudo dnf install htop"

notify-send 'Fedora Cache' "dnf local cache configured at $MOUNT_POINT"
