#!/bin/bash
set -euo pipefail

# This script disables suspend/hibernation in order to let audio work with
# Zigbee on a server
#
# Source: https://forum.manjaro.org/t/howto-disable-turn-off-hibernate-completely/8033

sudo mkdir -p "/etc/systemd/sleep.conf.d"

sudo tee /etc/systemd/sleep.conf.d/no-hibernate.conf > /dev/null << EOL
    [Sleep]
    # disable hibernation
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
EOL

sudo mkdir -p "/etc/systemd/logind.conf.d"

sudo tee /etc/systemd/logind.conf.d/no-hibernate.conf > /dev/null << EOL
    [Login]
    # disable hibernation
    HibernateKeyIgnoreInhibited=no
EOL

echo "Done! Hibernation disabled."