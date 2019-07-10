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
    1) Initial Config
    2) Base Apps
    3) Intel GPU
    4) AMD GPU
    5) Virtualbox
    6) Virtualbox Guest
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_settings ;;
        2) fn_base_apps ;;
        3) fn_intel_gpu ;;        
        4) fn_amd_gpu ;;
        5) fn_virtual_box ;;
        7) fn_virtual_box_guest ;;
        *) $SHELL ;;
    esac
    done
}


function fn_intel_gpu {
    # https://forum.manjaro.org/t/intel-j5005-uhd-graphics-605-gemini-lake-hardware-video-acceleration-not-working/57462/6
    yay --noconfirm -S libva-intel-driver intel-hybrid-codec-driver intel-media-driver
}


function fn_settings {
    # disable broken kde search
    balooctl disable
    
    # fix systemd shutdown timeout
    sudo sed -i -e "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g" /etc/systemd/system.conf
    sudo sed -i -e "s/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g" /etc/systemd/system.conf
    
    # fix logs to be no more than 50mb
    sudo sed -i -e "s/#SystemMaxUse=/SystemMaxUse=50M/g"  /etc/systemd/journald.conf

    # add to top of mirror list and update
    # http://repo.manjaro.org/
    sudo pacman-mirrors -c all # remove custom
    #sudo pacman-mirrors --country Australia
    
    # update database
    sudo pacman -Syy
    
    fn_aur_helper

    echo 'install complete'
    notify-send 'Config Settings' 'Install completed'
}


function fn_aur_helper {
    sudo pacman -S yay --noconfirm --needed
    sudo pacman -S pacui --noconfirm --needed
}


function fn_amd_gpu {
    yay -S --noconfirm radeon-profile-daemon-git radeon-profile-git
    systemctl enable radeon-profile-daemon.service
    systemctl start radeon-profile-daemon.service
}


function fn_base_apps {
    fn_aur_helper
    # remove old stuff
    #use pactree qt4 - to list packages dependancies
    echo 'Removing packages...'
    for pkg in yakuake xterm manjaro-hello octopi-notifier-frameworks octopi-cachecleaner octopi-repoeditor octopi calligra kget
    do
        yay -Rs --noconfirm $pkg
    done

    # install software
    echo 'Installing packages...'
    for pkg in openssh falkon syncthing redshift plasma-wayland-session plasma5-applets-redshift-control python-xdg xorg-xrandr udftools cantata plasma-browser-integration qbittorrent qjournal libreoffice
    do
        yay -S --noconfirm --needed $pkg
    done
    
    echo 'Installing dev apps...'
    for pkg in visual-studio-code-bin guitar smartgit blender audacity krita obs-studio
    do
        yay -S --noconfirm --needed $pkg
    done
    

    # extras
    # sound-juicer smartgit riot-desktop openwmail-bin 
    # netbeans virtualbox vidcutter xnviewmp avidemux trojita handbrake kube
    # nheko
    
    # fix redshift append
sudo tee -a /etc/geoclue/geoclue.conf > /dev/null << EOL

[redshift]
allowed=true
system=false
users=
EOL

    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    # remove orphan files
    sudo pacman -Rs --noconfirm $(pacman -Qqdt)

    echo 'install complete'
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
    sudo pacman -S linux$kernel-headers
    yay -S --noconfirm linux$kernel-virtualbox-guest-modules
    yay -S --noconfirm virtualbox-guest-utils
    sudo mkdir /media
    sudo modprobe vboxdrv
    sudo usermod -aG vboxusers $USER
    sudo systemctl enable vboxservice
}



# pass all args
main "$@"