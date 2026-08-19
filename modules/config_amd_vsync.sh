#!/bin/bash
set -euo pipefail

# script to fix tearing on AMD GPU's
# https://wiki.archlinux.org/index.php/AMDGPU

sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/20-amdgpu.conf > /dev/null << 'EOL'
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "TearFree" "true"
EndSection
EOL

echo "Done!"