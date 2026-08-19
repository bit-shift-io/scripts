#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# install software
echo -e '\n\nInstalling packages...'
"$UTIL" -i partitionmanager skanlite filelight kio-extras plasma-browser-integration isoimagewriter okular skanpage

echo -e '\n\ninstall complete'
if command -v notify-send > /dev/null 2>&1; then
    notify-send 'Applications' 'Install completed'
fi