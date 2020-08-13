#!/bin/bash

function main {
    # fix screen resolution
    #xrandr --output HDMI1 --set audio force-dvi --mode 1920x1080

    # delay load
    sleep 20s
    syncthing &
    /bin/python $HOME/Projects/scripts/cec.py &
}

# pass all args
main "$@"