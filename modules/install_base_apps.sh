#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# install software
echo -e '\n\nInstalling packages...'
"$UTIL" -i yay base-devel openssh libreoffice firefox keepassxc git rustup vulkan-drivers sshfs qbittorrent zed

# printer support
"$UTIL" -i cups cups-pdf system-config-printer avahi
sudo systemctl enable --now cups.service

# enable ssh (sshd on arch/fedora, ssh on debian)
ssh_service=sshd
if [[ -e /usr/lib/systemd/system/ssh.service ]] ; then
    ssh_service=ssh
fi
sudo systemctl enable "${ssh_service}.service"
sudo systemctl start "${ssh_service}.service"

# enable bluetooth
if [[ -e /usr/lib/systemd/system/bluetooth.service ]] ; then
    sudo systemctl enable bluetooth
fi

# disable firewall - if present (endevour)
if [[ -e /usr/lib/systemd/system/firewalld.service ]] ; then
    sudo systemctl stop firewalld
    sudo systemctl disable --now firewalld
fi

echo -e '\n\ninstall complete'
if command -v notify-send > /dev/null 2>&1; then
    notify-send 'Applications' 'Install completed'
fi