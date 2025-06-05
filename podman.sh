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
    server tools
    ===================
    1) Podman Install - Arch
    2) Podman Install - Debian/Arbmain
    r) Remove All Containers
    b) Backup podman folder
    u) Update containers
    *) Any key to exit
    :" ans;
    reset
    case $ans in 
        1) fn_install_arch ;;
        2) fn_install_debian ;;
        r) fn_remove_all ;;
        b) fn_backup ;;
        u) fn_update ;;
        *) $SHELL ;;
    esac
    done
}


function fn_update {
    echo "available updates:"
    podman auto-update --dry-run
    
    echo -n "apply all updates? [y/N]"
    read -r answer
    
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Applying updates..."
        podman auto-update
        echo "Updates applied."
    else
        echo "Skipping updates."
    fi
}


function fn_backup {
    echo "backup docker folder..."
    hostname=$(hostname)
    archive=$HOME/Backups/podman-${hostname}.tar.gz
    backup=$HOME/Containers
    
    #echo "listing containers"
    #containers=$(docker container list -qa)
    #echo $containers

    mkdir $HOME/Backups

    echo "stop containers"
    podman pause --all

    echo "create backup..."
    echo ${archive}
    sudo tar -czvf ${archive} ${backup} > /dev/null

    echo "restart containers"
    podman unpause --all

    echo "done!"
}


function fn_install_debian {
    echo "todo"
}


function fn_install_arch {
    ./util.sh -i podman crun
    
    # podlet: need rust to compile, untile a bin version is released
    rustup default stable
    ./util.sh -i podlet # yay
    
    sudo systemctl start podman --now
}


function fn_remove_all {
    podman rm --all
    podman ps --all
}


# pass all args
main "$@"
