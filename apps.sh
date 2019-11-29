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
    1) Manjaro Database
    2) Base Apps
    3) Extra Apps
    5) Virtualbox
    6) Virtualbox Guest
    9) Intel GPU
    0) AMD GPU
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_manjaro_database ;;
        2) fn_base_apps ;;
        3) fn_extra_apps ;;
        5) fn_virtual_box ;;
        6) fn_virtual_box_guest ;;
        9) fn_intel_gpu ;;        
        0) fn_amd_gpu ;;
        *) $SHELL ;;
    esac
    done
}


function fn_intel_gpu {
    # https://forum.manjaro.org/t/intel-j5005-uhd-graphics-605-gemini-lake-hardware-video-acceleration-not-working/57462/6
    yay --noconfirm -S libva-intel-driver intel-hybrid-codec-driver intel-media-driver
}


function fn_manjaro_database {
    # add to top of mirror list and update
    # http://repo.manjaro.org/
    #sudo pacman-mirrors -c all # remove custom
    sudo pacman-mirrors --country Australia,New_Zealand,United_States
    
    # update database
    sudo pacman -Syy

    # aur helper
    sudo pacman -S yay --noconfirm --needed
    sudo pacman -S pacui --noconfirm --needed
    
    echo 'install complete'
    notify-send 'Config Settings' 'Install completed'
}


function fn_amd_gpu {
    yay -S --noconfirm radeon-profile-daemon-git radeon-profile-git
    sudo systemctl enable radeon-profile-daemon.service
    sudo systemctl start radeon-profile-daemon.service
}


function fn_base_apps {
    # remove old stuff
    #use pactree qt4 - to list packages dependancies
    echo -e '\n\nRemoving packages...'
    ./util.sh -r xterm manjaro-hello pamac-gtk octopi-notifier-frameworks octopi-cachecleaner octopi-repoeditor octopi calligra kget yakuake plasma-wayland-session python-xdg xorg-xrandr udftools pamac-qt

    # install software
    echo -e '\n\nInstalling packages...'
    ./util.sh -i openssh falkon syncthing cantata plasma-browser-integration qbittorrent libreoffice firefox thunderbird
    
    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}

function fn_extra_apps {
    echo -e '\n\nInstalling extra apps...'
    ./util.sh -i code guitar blender audacity krita obs-studio inkscape barrier

    # extras
    # sound-juicer smartgit riot-desktop openwmail-bin 
    # vidcutter xnviewmp avidemux trojita handbrake kube
    # nheko
    # nitroshare lanshare


    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}


function fn_virtual_box {
    kernel=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')")
    yay -S --noconfirm $kernel-virtualbox-host-modules
    yay -S --noconfirm virtualbox virtualbox-ext-oracle
    sudo modprobe vboxdrv
    sudo usermod -aG vboxusers $USER
}

function fn_virtual_box_guest {
    kernel=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')")
    echo "kernel: ${kernel}"
    yay -S --noconfirm --needed $kernel-headers
    #yay -S --noconfirm --needed $kernel-virtualbox-guest-modules
    #yay -S --noconfirm --needed virtualbox-guest-dkms # shouldnt need guest-modules with this
    yay -S --noconfirm --needed xf86-video-vmware
    yay -S --needed virtualbox-guest-utils # user input required, installs guest-modules also
    
    echo "kernel: ${kernel}"
    # automount broken, roll our own bellow!
    #sudo mkdir /media
    #sudo chown -R $USER:vboxsf /media
    #sudo chmod -R 755 /media
    
    sudo modprobe -a vboxguest vboxsf vboxvideo
    sudo usermod -aG vboxsf $USER
    sudo systemctl enable vboxservice
    
    shares=$(sudo VBoxControl sharedfolder list | grep -Po "(?<=[0-9]{2} - ).*(?= \[id)")
    echo ""
    echo "Create automounts for:"
    echo "$shares"
    
    for share in ${shares[@]}; do
        create_vbox_mount ${share}
    done
}


function create_vbox_mount {
    sudo mkdir -p /mnt/vbox/${1}
    sudo chown -R $USER:vboxsf /mnt/vbox/${1}
    
# mount
sudo tee /etc/systemd/system/mnt-vbox-${1}.mount > /dev/null << EOL 
    [Unit]
    Description=vbox share

    [Mount]
    # vbox share name
    What=${1}
    Where=/mnt/vbox/${1}
    Options=noauto,nofail
    TimeoutSec=2
    ForceUnmount=true
    Type=vboxsf

    [Install]
    WantedBy=multi-user.target
EOL

# autmount
sudo tee /etc/systemd/system/mnt-vbox-${1}.automount > /dev/null << EOL   
    [Unit]
    Description=vbox share

    [Automount]
    Where=/mnt/vbox/${1}
    TimeoutIdleSec=60

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-vbox-${1}.automount
    sudo systemctl restart mnt-vbox-${1}.automount
}

# pass all args
main "$@"
