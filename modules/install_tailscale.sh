#!/bin/bash

echo "installing..."

./util.sh -i tailscale
#tailscale up
#tailscale configure systray --enable-startup=systemd
sudo systemctl --user daemon-reload
sudo systemctl enable tailscaled --now

#sudo tailscale up
sudo tailscale up --accept-routes
sudo tailscale set --operator=$USER
systemctl --user enable --now tailscale-systray

#../util.sh -i ktailctl

echo "Complete"
