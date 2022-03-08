#!/bin/bash

function main {
    # fix screen resolution
    #xrandr --output HDMI1 --set audio force-dvi --mode 1920x1080

    # wake up the screen
    echo 'on 0' | cec-client -s
    
    sleep 5s
    /bin/python $HOME/Projects/scripts/cec.py &
    #$HOME/Applications/zigbee2mqtt/start.sh &
    # hass &

    # bose on plz!
    $HOME/Projects/scripts/bose_power.sh &

    # delay load
    sleep 5s
    syncthing
    #syncthing -no-browser &
    #krfb --nodialog & # this causes KDE wallet problems! disabling for now

}

# pass all args
main "$@"
