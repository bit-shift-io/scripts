#!/bin/bash

function main {
    # fix screen resolution
    #xrandr --output HDMI1 --set audio force-dvi --mode 1920x1080

    sleep 5s
    /bin/python $HOME/Projects/scripts/cec.py &

    # delay load
    sleep 5s
    syncthing &
    krfb --nodialog &
}

# pass all args
main "$@"
