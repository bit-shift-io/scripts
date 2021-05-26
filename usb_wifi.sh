#!/bin/bash

sudo pacman -S $(ls /boot | awk -F "-" '/^linux/ { print $1"-headers" }')
yay -S rtl88x2bu-dkms-git
