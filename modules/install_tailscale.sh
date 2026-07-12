#!/bin/bash

echo "installing..."

./util.sh -i tailscale
#tailscale up
#tailscale configure systray --enable-startup=systemd
systemctl --user daemon-reload

sudo tailscale set --operator=$USER
sudo systemctl start tailscaled

#sudo tailscale up
sudo tailscale up --accept-routes


systemctl --user enable --now tailscale-systray

#../util.sh -i ktailctl

echo "Complete"
