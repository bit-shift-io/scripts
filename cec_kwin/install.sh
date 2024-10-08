#!/bin/bash


#
# install required tools
# qdbus
#

sudo pacman -S qt6-tools

#
# install the kwin script
#

#cd package
#zip -r ../cec_kwin.zip .
#cd ..

#kpackagetool6 --type=KWin/Script -i ./cec_kwin.zip

kpackagetool6 --type=KWin/Script -i ./package/

#
# setup a systemd service to run on bootup, which listens for the kwin script
#

mkdir -p $HOME/.config/systemd/user/

DIR="$( cd "$( dirname "$0" )" && pwd )"

tee $HOME/.config/systemd/user/cec_kwin.service > /dev/null << EOL 

[Unit]
Description=cec_kwin - Connect your external CEC device in order to turn your TV/Monitor on and off when KDE attempts to do so.
StartLimitIntervalSec=60
StartLimitBurst=4

[Service]
ExecStart=${DIR}/dbus_service.py
Restart=on-failure
RestartSec=1
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

# Hardening
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
NoNewPrivileges=true

# Elevated permissions to sync ownership (disabled by default),
# see https://docs.syncthing.net/advanced/folder-sync-ownership
#AmbientCapabilities=CAP_CHOWN CAP_FOWNER

[Install]
WantedBy=default.target

EOL


systemctl --user enable cec_kwin.service
systemctl --user start cec_kwin.service


#
# activate the kwin script
#

kwriteconfig5 --file kwinrc --group Plugins --key cec_kwinEnabled true
qdbus6 org.kde.KWin /KWin reconfigure


#
# display status
#

systemctl --user status cec_kwin
