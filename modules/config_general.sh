#!/bin/bash
set -euo pipefail

# backup before editing
sudo cp /etc/systemd/system.conf /etc/systemd/system.conf.bak
sudo cp /etc/systemd/journald.conf /etc/systemd/journald.conf.bak

# fix systemd shutdown timeout
sudo sed -i -e "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g" /etc/systemd/system.conf
sudo sed -i -e "s/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g" /etc/systemd/system.conf

# fix logs to be no more than 50mb
sudo sed -i -e "s/#SystemMaxUse=/SystemMaxUse=50M/g"  /etc/systemd/journald.conf

# disable broken kde search
if command -v balooctl > /dev/null 2>&1; then
    balooctl disable
fi

if command -v notify-send > /dev/null 2>&1; then
    notify-send 'Config' 'General config complete'
fi