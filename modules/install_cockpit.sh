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
./util.sh -i cockpit cockpit-files cockpit-packagekit cockpit-storaged
./util.sh -i cockpit-docker # this needs aur/yay
sudo systemctl enable cockpit.socket --now
echo "Complete"
}


function fn_debian {
./util.sh -i cockpit cockpit-files cockpit-packagekit cockpit-storaged #cockpit-networkmanager
./util.sh -i xz-utils

cd $HOME

# docker
wget -c https://github.com/chabad360/cockpit-docker/releases/download/16/cockpit-docker-16.tar.xz
echo "Extracting:"
sudo tar -xf cockpit-docker-16.tar.xz -C /usr/share/cockpit --checkpoint=.
#sudo sed -i 's/v1\.12/v1\.24/g' /usr/share/cockpit/docker/docker.js

# files, should be available in future repo
wget -c https://github.com/cockpit-project/cockpit-files/releases/download/13/cockpit-files-13.tar.xz
echo "Extracting:"
sudo tar -xf cockpit-files-13.tar.xz -C /usr/share/cockpit --checkpoint=.

sudo systemctl enable cockpit.socket --now
echo "Complete"
}


# pass all args
main "$@"


