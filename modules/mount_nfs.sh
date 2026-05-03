#!/bin/bash

function add_mount {
    local_path=$1
    host=$2
    remote_path=$3

    # Create local directory if it doesn't exist
    # dont need this, systemd does it?
    #sudo mkdir -p "$local_path"

    # Clean path name to the form mnt-nas-folder (systemd naming convention)
    # Remove leading slash, replace remaining slashes with dashes
    path_name="${local_path#/}"
    path_name="${path_name//\//-}"

    echo "Creating systemd units for: $local_path as $path_name.mount"

    # --- Create .mount unit ---
    sudo tee /etc/systemd/system/"$path_name".mount > /dev/null << EOL
[Unit]
Description=NFS mount for $path_name
After=network-online.target
Wants=network-online.target

[Mount]
What=$host:$remote_path
Where=$local_path
Type=nfs
Options=_netdev,rw,soft,intr,tcp
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOL

    # --- Create .automount unit ---
    sudo tee /etc/systemd/system/"$path_name".automount > /dev/null << EOL
[Unit]
Description=NFS automount for $path_name

[Automount]
Where=$local_path
TimeoutIdleSec=600

[Install]
WantedBy=multi-user.target
EOL

    # Reload and enable
    sudo systemctl daemon-reload
    sudo systemctl enable "$path_name".automount
    sudo systemctl restart "$path_name".automount
}

## ==== MAIN CODE ====

# NFS doesn't use a 'user' variable for the mount itself
echo "Enter NFS host (e.g., media.lan or ip):"
read remote_host

echo "Enter remote path on NAS (e.g., /mnt):"
read remote_path

echo "Enter local mount point (e.g., /mnt/nas):"
read local_path

add_mount "$local_path" "$remote_host" "$remote_path"

# Display list of active automounts
echo "--- Current Automounts ---"
systemctl list-units --type=automount --state=active

notify-send 'NFS Mount' "Automount for $local_path configured."
