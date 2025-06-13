#!/bin/bash

# test
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save

# make permanent
sudo tee /etc/modprobe.d/audio_power_save.conf > /dev/null << EOL
options snd_hda_intel power_save=0
EOL
