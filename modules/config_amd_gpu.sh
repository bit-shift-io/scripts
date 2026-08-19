#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

"$UTIL" -i radeon-profile-daemon-git radeon-profile-git
sudo systemctl enable radeon-profile-daemon.service
sudo systemctl start radeon-profile-daemon.service