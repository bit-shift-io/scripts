#!/bin/bash
set -euo pipefail

local_path=/swapfile
# ${string/regexp/replacement}
swap_path_name="${local_path////-}"
swap_path_name="${swap_path_name:1:${#swap_path_name}}"
echo "Mounting: $local_path as $swap_path_name"

# create swap
sudo swapoff -a

echo "How much swap in GB (eg 16 = 16GB): "
read -r swap_size

# btrfs specific
sudo truncate -s 0 "$local_path"
if command -v chattr > /dev/null 2>&1; then
    sudo chattr +C "$local_path"
fi
if command -v btrfs > /dev/null 2>&1; then
    sudo btrfs property set "$local_path" compression none
fi

sudo fallocate -l "${swap_size}G" "$local_path"
sudo chmod 0600 "$local_path"

# make swap and turn it on
sudo mkswap "$local_path"
sudo swapon "$local_path"

sudo bash -c "cat > /etc/systemd/system/$swap_path_name.swap" << EOL
    [Unit]
    Description=mount swap

    [Swap]
    What=$local_path

    [Install]
    WantedBy=multi-user.target
EOL

# enable swap
sudo systemctl enable "$swap_path_name.swap"

# show status
free -m

if command -v notify-send > /dev/null 2>&1; then
    notify-send 'Swap' 'Created'
fi