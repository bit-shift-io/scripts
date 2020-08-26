#!/bin/bash

function main {
    # fix screen resolution
    #xrandr --output HDMI1 --set audio force-dvi --mode 1920x1080

    # delay load
    sleep 10s
    syncthing &
    /bin/python $HOME/Projects/scripts/cec.py &
    krfb --nodialog &
}

# pass all args
main "$@"
