#!/bin/bash

function add_mount {
    local local_path="$1"
    local remote_path="$2"
    local smb_username="$3"
    local smb_password="$4"
    local use_current_user_ids="$5"

    # 1. Generate the systemd-compliant name (Critical for paths like /mnt/nas)
    local smb_path_name=$(systemd-escape --path "$local_path")

    echo "Configuring: $local_path as $smb_path_name"

    # 2. Get UID/GID for the current user
    local id_options=""
    if [ "$use_current_user_ids" = true ]; then
        sudo mkdir -p "$local_path"
        # Map the mount so your CachyOS user (1000) owns the files locally
        id_options="uid=$(id -u),gid=$(id -g),"
    fi

    # 3. Create Credentials file
    sudo mkdir -p /etc/samba
    sudo tee /etc/samba/smbcreds > /dev/null << EOL
username=$smb_username
password=$smb_password
EOL
    sudo chmod 600 /etc/samba/smbcreds

    # 4. Create Mount Unit
    sudo tee "/etc/systemd/system/$smb_path_name.mount" > /dev/null << EOL
[Unit]
Description=SMB Mount for $local_path
After=network-online.target

[Mount]
What=$remote_path
Where=$local_path
Type=cifs
TimeoutSec=10
Options=uid=1000,gid=1000,forceuid,forcegid,credentials=/etc/samba/smbcreds,rw,mfsymlinks,nobrl,noserverino,iocharset=utf8,_netdev

[Install]
WantedBy=multi-user.target
EOL

    # 5. Create Automount Unit
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

## ==== MAIN CODE ====
read -p "Enter host (e.g., media.lan): " remote_host
read -p "Enter remote path on NAS (e.g., /media): " remote_dir
read -p "Enter local mount point (e.g., /mnt/media): " local_path
read -p "Enter smb username: " smb_user
read -s -p "Enter smb password: " smb_pass
echo ""

# Clean up remote path: remove leading slash if user entered one
remote_dir_clean=$(echo "$remote_dir" | sed 's|^/||')
full_remote_path="//$remote_host/$remote_dir_clean"

# Pass 'true' to ensure the mount is owned by your current local user
add_mount "$local_path" "$full_remote_path" "$smb_user" "$smb_pass" true

# Display status
# Display list of active automounts
echo "--- Current Automounts ---"
systemctl list-units --type=automount --state=active
#systemctl list-units --type=automount | grep "$smb_path_name"
notify-send 'Mount' "Mount for $local_path Completed"
