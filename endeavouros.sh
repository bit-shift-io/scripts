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
    config
    ===================
    1) Disable Firewall
    2) Enable Blutooth

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_setup_firewall ;;
        2) fn_enable_bluetooth ;;
        *) $SHELL ;;
    esac
    done
}

function fn_setup_firewall {
    # https://discovery.endeavouros.com/applications/firewalld/2022/03/
    sudo systemctl stop firewalld
    sudo systemctl disable --now firewalld
    #sudo pacman -R firewalld
}

function fn_enable_bluetooth {
    sudo systemctl enable bluetooth
}

# pass all args
main "$@"