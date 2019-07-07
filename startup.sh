#!/bin/bash

function main {
    # simple autostart script
    redshift &
    pulseeffects --gapplication-service &

    # delay load
    sleep 20s
    syncthing &
    /bin/python $HOME/scripts/cec.py &
    $HOME/Applications/airdcpp-webclient/airdcppd &
}

# pass all args
main "$@"