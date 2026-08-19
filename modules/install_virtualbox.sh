#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

kernel=$(uname -r | awk -F "." '{print "linux"$1$2}')
"$UTIL" -i "${kernel}-virtualbox-host-modules"
"$UTIL" -i virtualbox virtualbox-ext-oracle
sudo modprobe vboxdrv
sudo usermod -aG vboxusers "$USER"