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
    
    tools
    ===================
    y) youtube download
    
    
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        c) ./modules/install_cockpit.sh ;;
        s) ./modules/install_fish.sh ;;
        y) ./modules/youtube_download.sh ;;
        *) $SHELL ;;
    esac
    done
}

# pass all args
main "$@"
