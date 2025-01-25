#!/bin/bash

# https://wiki.archlinux.org/title/IOS

./util.sh -i libimobiledevice usbmuxd
./util.sh -i qt6-heic-image-plugin

echo "Complete - plugin iphone and use file browser to access"
