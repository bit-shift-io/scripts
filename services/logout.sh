#!/bin/bash

echo 'standby 0' | cec-client -s

# turn off tv on media pc
irsend SEND_ONCE Samsung KEY_POWER