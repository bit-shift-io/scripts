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
echo "Complete"
}


function fn_debian {
./util.sh -i cockpit cockpit-files cockpit-packagekit cockpit-storaged


# docker
#wget https://launchpad.net/ubuntu/+source/cockpit/215-1~ubuntu19.10.1/+build/18889196/+files/cockpit-docker_215-1~ubuntu19.10.1_all.deb
#sudo dpkg -i cockpit-docker_215-1~ubuntu19.10.1_all.deb

cd $HOME

# docker
wget https://github.com/mrevjd/cockpit-docker/releases/download/v2.0.3/cockpit-docker.tar.gz
sudo tar xf cockpit-docker.tar.gz -C /usr/share/cockpit

# files, should be available in future repo
./util.sh xz-utils
wget https://github.com/cockpit-project/cockpit-files/releases/download/13/cockpit-files-13.tar.xz
sudo tar xf cockpit-files-13.tar.xz -C /usr/share/cockpit

# cockpit-networkmanager
echo "Complete"
}


# pass all args
main "$@"


