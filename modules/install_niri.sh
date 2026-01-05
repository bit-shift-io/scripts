#!/bin/bash

# fish shell
# yazi file manager
# niri tiling wm
# brightnessctl laptop display
./util.sh -i niri noctalia-shell swayidle wlsunset wluma

# fish niri yazi alaricitty brightnessctl

# dank material shell - noctalia is better
# curl -fsSL https://install.danklinux.com | sh


# user service
tee ~/.config/systemd/user/wluma.service > /dev/null << EOL
[Unit]
Description=Adjusting screen brightness based on screen contents and amount of ambient light
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=/usr/bin/wluma
Restart=always
EnvironmentFile=-%E/wluma/service.conf
PrivateNetwork=true
PrivateMounts=false

[Install]
WantedBy=graphical-session.target
EOL

systemctl --user enable --now wluma

# udev rules for auto brightness
#sudo tee /etc/udev/rules.d/90-wluma-backlight.rules > /dev/null << EOL
#ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
#ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
#ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chgrp video /sys/class/leds/%k/brightness"
#ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
#EOL

echo "Complete"
