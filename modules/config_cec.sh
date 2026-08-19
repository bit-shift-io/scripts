#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# https://wiki.archlinux.org/index.php/Users_and_groups#User_management
"$UTIL" -i libcec

USER=$(id -un)
sudo gpasswd -a "$USER" uucp
sudo gpasswd -a "$USER" lock
getent group uucp

if command -v notify-send > /dev/null 2>&1; then
    notify-send 'CEC' 'Please reboot!'
fi