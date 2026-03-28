#!/usr/bin/env bash

# Allow KDE connect through the firewall on Catchy
#
# https://www.reddit.com/r/cachyos/comments/1rta90c/kde_connect_phone_and_laptop_not_connecting/
#
#
# KDE Connect
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp

# Node red home
sudo ufw allow 1880/tcp

sudo ufw reload

echo "Done!"
