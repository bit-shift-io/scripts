#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

echo "Enter visible bluetooth name: "
read -r bluetooth_name

"$UTIL" -i python-dbus

# bluetooth config
sudo sed -i "s/.*Name =.*/Name = ${bluetooth_name}/" /etc/bluetooth/main.conf
sudo sed -i 's/#DiscoverableTimeout = 0/DiscoverableTimeout = 0/' /etc/bluetooth/main.conf
sudo sed -i 's/#AlwaysPairable = false/AlwaysPairable = true/' /etc/bluetooth/main.conf
sudo sed -i 's/#PairableTimeout = 0/PairableTimeout = 0/' /etc/bluetooth/main.conf
sudo sed -i 's/#JustWorksRepairing.*/JustWorksRepairing = always/' /etc/bluetooth/main.conf
sudo sed -i 's/#AutoEnable=true/AutoEnable=true/' /etc/bluetooth/main.conf

# user systemd service
sudo tee /usr/lib/systemd/user/bt.service > /dev/null << EOL
[Unit]
Description=Bluetooth speaker agent
After=network.target bluetooth.service dbus.service

[Service]
TimeoutStartSec=60
ExecStartPre=/usr/bin/sleep 20
Environment=PYTHONUNBUFFERED=1
ExecStart=python "$ROOT_DIR/services/speaker-agent.py"

[Install]
WantedBy=default.target
EOL

sudo systemctl daemon-reload
sudo systemctl --global enable bt.service
sudo systemctl start bt.service