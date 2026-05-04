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
    steam
    ===================
    l) Local
    n) NAS/Network

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        l) fn_setup_steam ;;
        n) fn_nas ;;
        *) $SHELL ;;
    esac
    done
}


function fn_nas {
    ./util.sh -i steam
    rm -r $HOME/.local/share/Steam

    # create symlinks
    ln -sfn /mnt/media/4-pcie/Games $HOME/Games
    ln -sfn $HOME/Games/Steam $HOME/.local/share/Steam

    # create compat tools dir if missing
    mkdir $HOME/Games/Steam/compatibilitytools.d

    # steam fix
    # find ~/.steam/root/ \( -name "libgcc_s.so*" -o -name "libstdc++.so*" -o -name "libxcb.so*" -o -name "libgpg-error.so*" \) -print -delete

    notify-send 'Steam' 'Game on!'
}

function fn_setup_steam {
    ./util.sh -i steam

    #mkdir
    mkdir -p $HOME/Games/Steam

    # move existing install
    mv $HOME/.local/share/Steam $HOME/Games

    # create compat tools dir
    mkdir $HOME/Games/Steam/compatibilitytools.d

    # remove unused
    rm -r $HOME/.local/share/Steam

    # create symlink
    #rm -r $HOME/.local/share/Steam
    ln -s $HOME/Games/Steam $HOME/.local/share/Steam

    # steam fix
    # find ~/.steam/root/ \( -name "libgcc_s.so*" -o -name "libstdc++.so*" -o -name "libxcb.so*" -o -name "libgpg-error.so*" \) -print -delete

    notify-send 'Steam' 'Game on!'
}

# pass all args
main "$@"
