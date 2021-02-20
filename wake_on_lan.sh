#!/bin/bash

# https://wiki.archlinux.org/index.php/Wake-on-LAN

# yay -S ethtool
# yay -S ngrep

# list all devices
ip a | grep enp

# does the one we use have wak on lan disabled (d)?
sudo ethtool enp37s0f0 | grep Wake-on

# just enable it on all devices
sudo ethtool -s enp37s0f0 wol umbg
#sudo ethtool -s enp34s0 wol g
#sudo ethtool -s enp37s0f1 wol g

# and again check its now magic packet ready (g)
sudo ethtool enp37s0f0 | grep Wake-on


nmcli con show

nmcli c show "Wired connection 1" | grep 802-3-ethernet.wake-on-lan

nmcli c modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic

nmcli c show "Wired connection 1" | grep 802-3-ethernet.wake-on-lan


# to check we are receiving the magic packet
# sudo ngrep '\xff{6}(.{6})\1{15}' -x port 9