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
    1) Setup Firewall
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
    # let docker through to access node-red dashboard on LAN
    sudo firewall-cmd --permanent --zone=home --add-port=1880/tcp

    # allow kdeconnect
    sudo firewall-cmd --permanent --zone=home --add-service=kdeconnect

    sudo firewall-cmd --reload
}

function fn_enable_bluetooth {
    sudo systemctl enable bluetooth
}

# pass all args
main "$@"