#!/bin/bash

## ==== MAIN CODE ====
echo "Enter label to automount: "
read drive_label

# mount
sudo tee /etc/systemd/system/mnt-${drive_label}.mount > /dev/null << EOL 
[Unit]
Description=automount of ${drive_label}

[Mount]
What=LABEL=${drive_label}
Where=/mnt/${drive_label}/
#Options=noauto,nofail
#TimeoutSec=2
#ForceUnmount=true

[Install]
WantedBy=multi-user.target

[Service]
TimeoutSec=2s # timeout for the mount
EOL

# autmount
sudo tee /etc/systemd/system/mnt-${drive_label}.automount > /dev/null << EOL   
[Unit]
Description=automount of ${drive_label}

[Automount]
Where=/mnt/${drive_label}/
TimeoutIdleSec=600s # 10 min timeout for unmount

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable mnt-${drive_label}.automount
sudo systemctl restart mnt-${drive_label}.automount

notify-send 'Mount' 'Mount Completed'
