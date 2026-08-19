#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# https://wiki.archlinux.org/title/IOS

"$UTIL" -i libimobiledevice usbmuxd
"$UTIL" -i qt6-heic-image-plugin

echo "Complete - plugin iphone and use file browser to access"
