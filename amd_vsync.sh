#!/bin/bash

# script to fix tearing on AMD GPU's

# https://wiki.archlinux.org/index.php/AMDGPU

sudo bash -c "cat > /etc/X11/xorg.conf.d/20-amdgpu.conf" << EOL 
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "TearFree" "true"
EndSection
EOL