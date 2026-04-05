#!/bin/bash
#
./util.sh -i cockpit cockpit-files cockpit-packagekit cockpit-storaged cockpit-networkmanager cockpit-podman cockpit-system cockpit-machines cockpit-sosreport
sudo systemctl enable cockpit.socket --now
echo "Complete"
