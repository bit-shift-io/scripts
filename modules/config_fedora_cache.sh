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

# dnf5 native local plugin + createrepo_c (required for metadata generation)
"$UTIL" -i python3-dnf-plugin-local
"$UTIL" -i createrepo_c

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

# seed repo metadata so the plugin repos are valid from first use,
# otherwise dnf aborts with "Could not read a file:// file" until the
# plugin writes its first package
for repo_dir in "$MOUNT_POINT" "$MOUNT_POINT-nogpgcheck"; do
    sudo mkdir -p "$repo_dir"
    if [[ ! -d "$repo_dir/repodata" ]]; then
        sudo createrepo_c "$repo_dir"
    fi
done

# configure the dnf5 local plugin (dnf4 used /etc/dnf/plugins/local.conf,
# dnf5 reads /etc/dnf/libdnf5-plugins/local.conf with a different format)
sudo rm -f /etc/dnf/plugins/local.conf
sudo tee /etc/dnf/libdnf5-plugins/local.conf > /dev/null << EOL
[main]
name = local
enabled = true
repodir = $MOUNT_POINT
repodir_nogpgcheck = $MOUNT_POINT-nogpgcheck

[createrepo]
enabled = true
EOL

echo "fedora cache ready: $MOUNT_POINT -> $SFTP_USER@$SFTP_HOST:$SFTP_PATH"
echo "test it with: sudo dnf install htop"
echo "then check: ls $MOUNT_POINT && dnf repolist | grep _dnf_local"

notify-send 'Fedora Cache' "dnf local cache configured at $MOUNT_POINT"
