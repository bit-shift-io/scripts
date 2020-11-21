#!/bin/bash

yay -S dialog lirc-git

# to record:

# these dont work:
irrecord -d /dev/ttyACM0 /etc/lirc/lircd.conf
irrecord -n -H irtoy -d /dev/ttyACM0 RemoteXXX.conf

# this somewhat works:
# https://gist.github.com/prasanthj/c15a5298eb682bde34961c322c95378b
sudo irrecord --driver default --device /dev/lirc0 ~/lircd.conf

sudo lircd --device=/dev/lirc0 --driver=irtoy

# press remote at the receiver with this command and you can verify output:
sudo cat /dev/lirc0 
