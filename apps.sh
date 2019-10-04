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
        6) fn_virtual_box_guest ;;
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
    #sudo pacman-mirrors -c all # remove custom
    sudo pacman-mirrors --country Australia,New_Zealand,United_States
    
    # update database
    sudo pacman -Syy

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
    for pkg in xterm manjaro-hello pamac-gtk octopi-notifier-frameworks octopi-cachecleaner octopi-repoeditor octopi calligra kget yakuake
    do
        yay -Rs --noconfirm $pkg
    done

    # install software
    echo 'Installing packages...'
    for pkg in openssh pamac-qt falkon syncthing plasma-wayland-session python-xdg xorg-xrandr udftools cantata plasma-browser-integration qbittorrent libreoffice firefox discover
    do
        yay -S --noconfirm --needed $pkg
    done
    
    echo 'Installing dev apps...'
    for pkg in visual-studio-code-bin guitar blender audacity krita obs-studio inkscape
    do
        yay -S --noconfirm --needed $pkg
    done
    

    # extras
    # sound-juicer smartgit riot-desktop openwmail-bin 
    # netbeans virtualbox vidcutter xnviewmp avidemux trojita handbrake kube
    # nheko
    # nitroshare


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
