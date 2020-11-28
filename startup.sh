#!/bin/bash

function main {
    # fix screen resolution
    #xrandr --output HDMI1 --set audio force-dvi --mode 1920x1080

    sleep 5s
    /bin/python $HOME/Projects/scripts/cec.py &
    $HOME/Applications/zigbee2mqtt/start.sh &
    hass &

    # delay load
    sleep 5s
    syncthing &
    krfb --nodialog &
}

# pass all args
main "$@"
