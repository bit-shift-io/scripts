#!/bin/bash
#
./util.sh -i cockpit cockpit-system cockpit-podman cockpit-files cockpit-packagekit
# extras maybe use of use?
# cockpit-machines cockpit-sosreport cockpit-networkmanager cockpit-storaged
sudo systemctl enable cockpit.socket --now
echo "Complete"
