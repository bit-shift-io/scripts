# Scripts

A bunch of arch based linux scripts for various things.

Primarily tested on Manjaro and EndeavourOS.

## Syncthing as a systemd service

Instructions on setting up syncthing to run as a systemd user service here: https://docs.syncthing.net/v1.0.0/users/autostart#how-to-set-up-a-user-service

In short, copy syncthing.service (I've a copy in the serivces dir) to ~/.config/systemd/user/

systemctl --user enable syncthing.service
systemctl --user start syncthing.service

systemctl --user status syncthing.service

## Docker

Once docker service is installed and running, each config file contains the command to run to start the docker container.

##  EndeavourOS

### Enable Bluetooth

sudo systemctl enable bluetooth

### Enable Docker network access (i.e. to access Node-red Dashboard)

EndeavourOS has a firewall enabled by default so to allow access to Node-red Dashboard running from Docker:

1) RMB > Edit Firewall Settings

2) Under the public Zone > Ports and add:

3) Port 1880, tcp.
