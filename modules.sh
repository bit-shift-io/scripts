#!/bin/bash

function main {
    # loop args
    if [[ $# -ne 0 ]] ; then
        for var in "$@" ; do
            eval $var
        done
        exit 1
    fi
    
    # menu
    while true; do
    read -n 1 -p "
    apps
    ===================
    1) cockpit
    
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) ./modules/install_cockpit.sh ;;
        *) $SHELL ;;
    esac
    done
}

# pass all args
main "$@"
