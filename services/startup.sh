#!/bin/bash

function main {
    # fix screen resolution
    #xrandr --output HDMI1 --set audio force-dvi --mode 1920x1080

    # wake up the screen
    #echo 'on 0' | cec-client -s
    
    # turn on tv on media pc
    irsend SEND_ONCE Samsung KEY_POWER

    #sleep 5s
    #/bin/python $HOME/Projects/scripts/services/cec.py &

    # delay load
    #sleep 5s
    #syncthing
    #syncthing -no-browser &
}

# pass all args
main "$@"
