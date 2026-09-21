#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

# disable broken kde search
#if command -v balooctl > /dev/null 2>&1; then
#    balooctl disable
#fi

# kde fullscreen spaces
cd /tmp/
git clone https://github.com/geodro/kde-fullscreen-spaces.git
cd kde-fullscreen-spaces
./install.sh

# install software
echo -e '\n\nInstalling packages...'
"$UTIL" -i partitionmanager skanlite filelight kio-extras plasma-browser-integration isoimagewriter okular skanpage krdc krdp



notify 'Config' 'KDE config complete'
