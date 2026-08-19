#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

"$UTIL" -i pipewire-zeroconf

sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

sudo tee /etc/pipewire/pipewire-pulse.conf.d/50-network-party.conf > /dev/null << EOL
context.exec = [
    { path = "pactl" args = "load-module module-native-protocol-tcp" }
    { path = "pactl" args = "load-module module-zeroconf-discover" }
    { path = "pactl" args = "load-module module-zeroconf-publish" }
]
EOL