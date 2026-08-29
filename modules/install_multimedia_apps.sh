#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

echo -e '\n\nInstalling media development apps...'
"$UTIL" -i blender audacity krita obs-studio inkscape handbrake

echo -e '\n\ninstall complete'
if command -v notify-send > /dev/null 2>&1; then
    notify-send 'Applications' 'Install completed'
fi