#!/usr/bin/env bash
# Input with Default Value
read -p "Local mirror IP/Hostname [default: update.lan]: " computer_name
computer_name="${computer_name:-update.lan}"

# Safety: Create a backup of the config
sudo cp /etc/pacman.conf /etc/pacman.conf.bak
echo "Backup created at /etc/pacman.conf.bak"

# Cleanup: Remove any existing local Server entries for this port
# We use a regex that catches any 'Server = http://...:9129' line
sudo sed -i "\|Server = http://.*:9129|d" /etc/pacman.conf

# Auto-Detect OS Type (Manjaro vs Arch)
if grep -iq "manjaro" /etc/pacman.conf; then
    base_repo="manjaro"
    std_suffix="\$repo/\$arch"
    echo "Detected Manjaro configuration..."
else
    base_repo="archlinux"
    std_suffix="\$repo/os/\$arch"
    echo "Detected Arch Linux configuration..."
fi

# Server Line Definitions
std_server="Server = http://${computer_name}:9129/repo/${base_repo}/${std_suffix}"
cachy_server="Server = http://${computer_name}:9129/repo/\$repo"

# Injection Logic
# Matches "Include = ...mirrorlist" regardless of trailing whitespace or hidden characters (\s*)
sudo sed -i "s|^\s*\(Include = /etc/pacman.d/mirrorlist\)|${std_server}\n\1|g" /etc/pacman.conf
sudo sed -i "s|^\s*\(Include = /etc/pacman.d/cachyos-v4-mirrorlist\)|${cachy_server}\n\1|g" /etc/pacman.conf
sudo sed -i "s|^\s*\(Include = /etc/pacman.d/cachyos-v3-mirrorlist\)|${cachy_server}\n\1|g" /etc/pacman.conf
sudo sed -i "s|^\s*\(Include = /etc/pacman.d/cachyos-mirrorlist\)|${cachy_server}\n\1|g" /etc/pacman.conf
# Finalize
notify-send 'Config' "Local mirrors prioritized to ${computer_name}"
echo "Done!"
