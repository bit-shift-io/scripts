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
./util.sh -i git gettext nodejs make


# docker
cd $HOME
git clone https://github.com/chabad360/cockpit-docker.git
cd cockpit-docker
make
sudo make install


# files, should be available in future repo
cd $HOME
git clone https://github.com/cockpit-project/cockpit-files.git
cd cockpit-files
make
sudo make install

sudo systemctl enable cockpit.socket --now
echo "Complete"
}


# pass all args
main "$@"


