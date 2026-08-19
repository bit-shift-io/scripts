#!/bin/bash
set -euo pipefail

echo "Enter drive label to automount: "
read -r drive_label || true

if [[ -z "${drive_label}" ]]; then
    echo "No label entered, aborting"
    exit 1
fi

# mount
sudo tee /etc/systemd/system/mnt-${drive_label}.mount > /dev/null << EOL
    [Unit]
    Description=automount of ${drive_label}

    [Mount]
    What=LABEL=${drive_label}
    Where=/mnt/${drive_label}/
    Options=noauto,nofail
    TimeoutSec=2
    ForceUnmount=true

    [Install]
    WantedBy=multi-user.target
EOL

# automount
sudo tee /etc/systemd/system/mnt-${drive_label}.automount > /dev/null << EOL
    [Unit]
    Description=automount of ${drive_label}

    [Automount]
    Where=/mnt/${drive_label}/
    TimeoutIdleSec=1800

    [Install]
    WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable mnt-${drive_label}.automount
sudo systemctl restart mnt-${drive_label}.automount