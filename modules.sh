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
    c) cockpit
    s) fish shell
    
    
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        c) ./modules/install_cockpit.sh ;;
        f) ./modules/install_fish.sh ;;
        *) $SHELL ;;
    esac
    done
}

# pass all args
main "$@"
