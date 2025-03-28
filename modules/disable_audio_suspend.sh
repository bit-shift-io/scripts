#!/bin/bash

# requires reboot
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save


# https://wiki.archlinux.org/title/PipeWire#Noticeable_audio_delay_or_audible_pop/crack_when_starting_playback
mkdir -p $HOME/.config/wireplumber/wireplumber.conf.d/

# /etc/wireplumber/wireplumber.conf.d/51-disable-suspension.conf
# ~/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf
tee $HOME/.config/wireplumber/wireplumber.conf.d/51-disable-suspension.conf > /dev/null << EOL
monitor.alsa.rules = [
  {
    matches = [
      {
        # Matches all sources
        node.name = "~alsa_input.*"
      },
      {
        # Matches all sinks
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      update-props = {
        session.suspend-timeout-seconds = 0
        dither.method = "wannamaker3", # add dither of desired shape
        dither.noise = 2, # add additional bits of noise
      }
    }
  }
]
# bluetooth devices
monitor.bluez.rules = [
  {
    matches = [
      {
        # Matches all sources
        node.name = "~bluez_input.*"
      },
      {
        # Matches all sinks
        node.name = "~bluez_output.*"
      }
    ]
    actions = {
      update-props = {
        session.suspend-timeout-seconds = 0
      }
    }
  }
]
EOL


systemctl restart --user pipewire.service
systemctl restart --user wireplumber.service
#systemctl restart pipewire.service
#systemctl restart wireplumber.service
