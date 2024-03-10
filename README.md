# scripts


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

