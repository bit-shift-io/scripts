#!/usr/bin/env bash

# Allow KDE connect through the firewall on Catchy
#
# https://www.reddit.com/r/cachyos/comments/1rta90c/kde_connect_phone_and_laptop_not_connecting/
#
sudo ufw allow 1714:1764/udp
sudo ufw allow 1714:1764/tcp
sudo ufw reload

echo "Done!"
