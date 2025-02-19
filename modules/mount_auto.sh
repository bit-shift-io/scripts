#!/bin/bash

## ==== MAIN CODE ====

# mount script
sudo cp ../services/usb-mount.sh /usr/local/bin/usb-mount.sh 
sudo chmod +x /usr/local/bin/usb-mount.sh

# mount service
# we use the "@" filename syntax so we can pass the device name as an argument
sudo tee /etc/systemd/system/usb-mount@.service > /dev/null << EOL 
[Unit]
Description=Mount USB Drive %i

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/usr/local/bin/usb-mount.sh add %i
ExecStop=/usr/local/bin/usb-mount.sh remove %i
EOL

# udev rules to exec the service
sudo tee /etc/udev/rules.d/99-local.rules > /dev/null << EOL 
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="add", RUN+="/bin/systemctl start usb-mount@%k.service"
KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="remove", RUN+="/bin/systemctl stop usb-mount@%k.service"
EOL


# enable service
sudo udevadm control --reload-rules
sudo systemctl daemon-reload

# systemctl status usb-mount@sda1


echo "Mount service installed"
notify-send 'Mount' 'Mount Completed'
