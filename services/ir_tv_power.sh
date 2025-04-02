#!/bin/bash

# this script uses the IR droid to turn TV on and Off when the PC boots and shutsdown
# Linux Infrared Remote Control utilities
# https://wiki.archlinux.org/title/Help:Reading#Control_of_systemd_units

# install deps and start the service
# yay -S lirc
# yay -S lirc-user-service


# change the driver
# in /etc/lirc/lirc_options.conf change:
# driver          = devinput
# to:
# driver          = default

# systemctl start lircd.service
# systemctl enable lircd.service

# to search and download some remotes:
# irdb-get find samsung

# my remote is labelled "AA59-00431A" this is the closest:
# irdb-get download samsung/AA59-00489A.lircd.conf

# copy into the config dir for usage
# sudo cp AA59-00489A.lircd.conf /etc/lirc/lircd.conf.d/

# rename the old default config/driver
# sudo mv /etc/lirc/lircd.conf.d/devinput.lircd.conf /etc/lirc/lircd.conf.d/devinput.lircd.dist 

# to see some codes from your remote without recording them use:
# irw

# if you want to record your own remotes to create a config file for usage
# irrecord --device=/dev/lirc0 MyRemote


# to list registered remotes:
# irsend LIST "" ""

# to list codes for a remote:
# irsend LIST Samsung ""

# to send a remote command:
irsend SEND_ONCE Samsung KEY_POWER