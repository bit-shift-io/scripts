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
    dietpi config
    ===================
    a) install amd drivers
    h) set hostname

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        a) fn_amd_driver ;;
        h) fn_hostname 1 ;;

        *) $SHELL ;;
    esac
    done
}


function fn_amd_driver {
    sudo apt update
    sudo apt install firmware-amd-graphics libgl1-mesa-dri
    lsmod | grep amdgpu
    echo "reboot now!"
}


# pass all args
main "$@"
