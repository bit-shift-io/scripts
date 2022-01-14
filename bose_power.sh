#!/bin/bash

# https://github.com/mjg59/python-broadlink/tree/master/cli

# setup:
#
# yay -S python-pip
# pip install broadlink
# yay -S python-broadlink
#
# OR
#
# grab the cli from here: https://github.com/mjg59/python-broadlink/tree/master/cli
# chmod +x broadlink_cli
#
# broadlink lib is probably here (unfortunately doesnt include the cli!):
#/home/s/.local/lib/python3.9/site-packages

# bose codes here: https://github.com/mjg59/python-broadlink/issues/545#event-4450216175
# these are in base64 so need to convert to hex and by running through here: https://base64.guru/converter/decode/hex

DIR=$HOME/Projects/scripts
cd $DIR

broadlink_cli --type 0x653c --host 192.168.1.100 --mac a043b032c784 --send 26004800000127941212123712121237123712371212123712371237121212371212121212371212121212121237123712121212123712121237123712121212123712371212123712000501

notify-send 'BOSE' 'Power toggled'