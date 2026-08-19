#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

"$UTIL" -i pipewire-zeroconf

sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

sudo tee /etc/pipewire/pipewire.conf.d/raop-discover.conf > /dev/null << EOL
context.modules = [
    {
        name = libpipewire-module-raop-discover
        args = { }
    }
]
EOL