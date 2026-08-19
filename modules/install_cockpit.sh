#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
#
"$UTIL" -i cockpit cockpit-system cockpit-podman cockpit-files cockpit-packagekit cockpit-storaged
# extras maybe use of use?
# cockpit-machines cockpit-sosreport cockpit-networkmanager
sudo systemctl enable cockpit.socket --now
echo "Complete"
