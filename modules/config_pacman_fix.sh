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
    u) Update force pacman
    f) Fix pacman keys
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        f) fn_fix_pacman ;;
        u) fn_update_pacman ;;
        *) $SHELL ;;
    esac
    done
}

function fn_fix_pacman {
    sudo pacman -Syy
    sudo pacman-key --refresh-keys
    sudo pacman-key --populate archlinux cachyos manjaro
    #sudo pacman-key --populate archlinux manjaro
    sudo ./util.sh -i archlinux-keyring
}

function fn_update_pacman {
    sudo ./util.sh -i archlinux-keyring cachyos-keyring
    sudo pacman -Syyu
}

# pass all args
main "$@"
