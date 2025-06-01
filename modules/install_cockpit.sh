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
    cockpit
    ===================
    1) archlinux
    2) debian/armbian
    
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_arch ;;
        2) fn_debian ;;
        *) $SHELL ;;
    esac
    done
}


function fn_arch {
./util.sh -i cockpit cockpit-files cockpit-packagekit cockpit-storaged cockpit-podman
./util.sh -i cockpit-docker # this needs aur/yay
sudo systemctl enable cockpit.socket --now
echo "Complete"
}


function fn_debian {
./util.sh -i cockpit cockpit-files cockpit-packagekit cockpit-storaged #cockpit-networkmanager
./util.sh -i git gettext nodejs make


# docker
cd $HOME
wget -c https://github.com/chabad360/cockpit-docker/releases/download/16/cockpit-docker-16.tar.xz
sudo tar xf cockpit-docker-16.tar.xz -C /tmp/
sudo mkdir -p /usr/share/cockpit/docker
sudo mv /tmp/cockpit-docker/dist/* /usr/share/cockpit/docker

# files, should be available in future repo
cd $HOME
wget -c https://github.com/cockpit-project/cockpit-files/releases/download/13/cockpit-files-13.tar.xz
sudo tar xf cockpit-files-13.tar.xz -C /tmp/
sudo mkdir -p /usr/share/cockpit/files
sudo mv /tmp/cockpit-files/dist/* /usr/share/cockpit/files

sudo rm -r /tmp/*

sudo systemctl enable cockpit.socket --now
echo "Complete"
}


# pass all args
main "$@"


