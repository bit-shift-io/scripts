#!/bin/bash

sudo systemctl mask NetworkManager-wait-online.service

# https://forum.manjaro.org/t/slow-firmware-boot-time-on-fresh-install/36678/16
# edit and change: 
# /etc/default/grub
# GRUB_TIMEOUT=10 to 1
# then:
# sudo update-grub
