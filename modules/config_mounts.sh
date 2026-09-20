#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

# Shared SSH key management
function ensure_ssh_key {
    local dest=$1
    local key="$HOME/.ssh/id_ed25519"

    if [[ ! -f "$key" ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -N "" -f "$key"
    fi

    if ! ssh -o BatchMode=yes -o IdentitiesOnly=yes -i "$key" -o ConnectTimeout=5 \
            "$dest" true 2> /dev/null; then
        echo "key not authorised on $dest yet, enter password when prompted:"
        ssh-copy-id -i "$key.pub" "$dest"
    fi
}

# SMB mount - interactive prompts + systemd units
function add_mount_smb {
    local local_path="$1"
    local remote_path="$2"
    local smb_username="$3"
    local smb_password="$4"
    local use_current_user_ids="$5"

    local smb_path_name=$(systemd-escape --path "$local_path")
    echo "Configuring: $local_path as $smb_path_name"

    local id_options=""
    if [ "$use_current_user_ids" = true ]; then
        sudo mkdir -p "$local_path"
        id_options="uid=$(id -u),gid=$(id -g),"
    fi

    sudo mkdir -p /etc/samba
    sudo tee /etc/samba/smbcreds > /dev/null << EOL
username=$smb_username
password=$smb_password
EOL
    sudo chmod 600 /etc/samba/smbcreds

    sudo tee "/etc/systemd/system/$smb_path_name.mount" > /dev/null << EOL
[Unit]
Description=SMB Mount for $local_path
After=network-online.target

[Mount]
What=$remote_path
Where=$local_path
Type=cifs
TimeoutSec=10
Options=uid=1000,gid=1000,forceuid,forcegid,credentials=/etc/samba/smbcreds,rw,file_mode=0755,dir_mode=0755,iocharset=utf8,_netdev

[Install]
WantedBy=multi-user.target
EOL

    sudo tee "/etc/systemd/system/$smb_path_name.automount" > /dev/null << EOL
[Unit]
Description=Automount for $local_path

[Automount]
Where=$local_path
TimeoutIdleSec=600s

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable --now "$smb_path_name.automount"
}

# NFS mount
function add_mount_nfs {
    local local_path="$1"
    local host="$2"
    local remote_path="$3"

    local path_name="${local_path#/}"
    path_name="${path_name//\//-}"

    echo "Creating systemd units for: $local_path as $path_name.mount"

    sudo tee /etc/systemd/system/"$path_name".mount > /dev/null << EOL
[Unit]
Description=NFS mount for $path_name
After=network-online.target
Wants=network-online.target

[Mount]
What=$host:$remote_path
Where=$local_path
Type=nfs
Options=_netdev,rw,soft,timeo=14,retrans=2,tcp,exec,nconnect=8,vers=4.2
TimeoutSec=10

[Install]
WantedBy=multi-user.target
EOL

    sudo tee /etc/systemd/system/"$path_name".automount > /dev/null << EOL
[Unit]
Description=NFS automount for $path_name

[Automount]
Where=$local_path
TimeoutIdleSec=60

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable "$path_name".automount
    sudo systemctl restart "$path_name".automount
}

# Mount by label
function add_mount_label {
    local drive_label="$1"

    sudo tee /etc/systemd/system/mnt-${drive_label}.mount > /dev/null << EOL
[Unit]
Description=automount of ${drive_label}

[Mount]
What=LABEL=${drive_label}
Where=/mnt/${drive_label}/
Options=noauto,nofail
TimeoutSec=2
ForceUnmount=true

[Install]
WantedBy=multi-user.target
EOL

    sudo tee /etc/systemd/system/mnt-${drive_label}.automount > /dev/null << EOL
[Unit]
Description=automount of ${drive_label}

[Automount]
Where=/mnt/${drive_label}/
TimeoutIdleSec=1800

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-${drive_label}.automount
    sudo systemctl restart mnt-${drive_label}.automount
}

# SSHFS mount
function add_mount_sshfs {
    local local_path="$1"
    local user="$2"
    local host="$3"
    local remote_path="$4"

    local uid=$(id -u)
    local gid=$(id -g)

    local path_name="${local_path////-}"
    path_name="${path_name:1:${#path_name}}"
    echo "Mounting: $local_path as $path_name"

    sudo tee /etc/systemd/system/$path_name.mount > /dev/null << EOL
[Unit]
Description=sshfs mount
Before=remote-fs.target

[Mount]
What=$user@$host:$remote_path
Where=$local_path
Type=fuse.sshfs
Options=_netdev,rw,nosuid,allow_other,uid=$uid,gid=$gid,default_permissions,follow_symlinks,idmap=user,reconnect,ServerAliveInterval=15,identityfile=$HOME/.ssh/id_ed25519,IdentitiesOnly=yes,UserKnownHostsFile=$HOME/.ssh/known_hosts,StrictHostKeyChecking=accept-new
TimeoutSec=30

[Install]
WantedBy=remote-fs.target
WantedBy=multi-user.target
EOL

    sudo tee /etc/systemd/system/$path_name.automount > /dev/null << EOL
[Unit]
Description=sshfs mount

[Automount]
Where=$local_path
TimeoutIdleSec=0

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable $path_name.automount
    sudo systemctl restart $path_name.automount
}

# USB auto-mount enable
function fn_usb_enable {
    sudo cp "$ROOT_DIR/services/usb-mount.sh" /usr/local/bin/usb-mount.sh
    sudo chmod +x /usr/local/bin/usb-mount.sh

    sudo tee /etc/systemd/system/usb-mount@.service > /dev/null << EOL
[Unit]
Description=Mount USB Drive %i

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/local/bin/usb-mount.sh add %i
ExecStop=/usr/local/bin/usb-mount.sh remove %i
EOL

    sudo tee /etc/udev/rules.d/99-local.rules > /dev/null << EOL
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="add", RUN+="/bin/systemctl start usb-mount@%k.service"
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="remove", RUN+="/bin/systemctl stop usb-mount@%k.service"
EOL

    sudo udevadm control --reload-rules
    sudo systemctl daemon-reload

    echo "Mount service installed"
    notify 'Mount' 'Mount Completed'
}

# USB auto-mount disable
function fn_usb_disable {
    sudo systemctl stop usb-mount@*.service
    sudo systemctl disable usb-mount@.service
    sudo rm /etc/systemd/system/usb-mount@.service
    sudo rm /etc/udev/rules.d/99-local.rules
    sudo systemctl daemon-reload
    sudo udevadm control --reload-rules
}

# Main menu
function main {
    if [[ $# -ne 0 ]]; then
        for var in "$@"; do
            $var
        done
        exit 0
    fi

    while true; do
        read -n 1 -p "
        mounts
        ===================
        s) SMB mount
        n) NFS mount
        l) Mount by label
        f) SSHFS mount
        u) USB auto-mount enable
        d) USB auto-mount disable

        *) Any key to exit
        :" ans;
        reset
        case $ans in
            s) fn_smb ;;
            n) fn_nfs ;;
            l) fn_label ;;
            f) fn_sshfs ;;
            u) fn_usb_enable ;;
            d) fn_usb_disable ;;
            *) exit 0 ;;
        esac
    done
}

function fn_smb {
    read -p "Enter host (e.g., media.lan): " remote_host
    read -p "Enter remote path on NAS (e.g., /media): " remote_dir
    read -p "Enter local mount point (e.g., /mnt/media): " local_path
    read -p "Enter smb username: " smb_user
    read -s -p "Enter smb password: " smb_pass
    echo ""
    local remote_dir_clean=$(echo "$remote_dir" | sed 's|^/||')
    local full_remote_path="//$remote_host/$remote_dir_clean"
    add_mount_smb "$local_path" "$full_remote_path" "$smb_user" "$smb_pass" true
    echo "--- Current Automounts ---"
    systemctl list-units --type=automount --state=active
}

function fn_nfs {
    echo "Enter NFS host (e.g., media.lan or ip):"
    read remote_host
    echo "Enter remote path on NAS (e.g., /mnt):"
    read remote_path
    echo "Enter local mount point (e.g., /mnt/nas):"
    read local_path
    add_mount_nfs "$local_path" "$remote_host" "$remote_path"
    echo "--- Current Automounts ---"
    systemctl list-units --type=automount --state=active
    findmnt -t nfs,nfs4
}

function fn_label {
    echo "Enter drive label to automount: "
    read -r drive_label || true
    if [[ -z "${drive_label}" ]]; then
        echo "No label entered, aborting"
        return 1
    fi
    add_mount_label "$drive_label"
}

function fn_sshfs {
    echo "Enter sftp user: "
    read remote_user
    echo "Enter sftp host eg host.lan: "
    read remote_host
    ensure_ssh_key "$remote_user@$remote_host"
    echo "Enter sftp path eg: /home/s/dir: "
    read remote_path
    echo "Enter local path eg: ${HOME}/path: "
    read local_path
    add_mount_sshfs "$local_path" "$remote_user" "$remote_host" "$remote_path"
    echo "--- Current Automounts ---"
    systemctl list-units --type=automount
    systemctl list-units --type=mount
}

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

main "$@"
