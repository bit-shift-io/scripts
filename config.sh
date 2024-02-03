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
    config
    ===================
    1) General config (systemd timeout, kde index, mirror list)
    2) Swap
    3) Steam
    
    apps
    ===================
    4) Base Apps
    6) Code Development Apps
    7) Media Development Apps

    extras
    ===================
    a) Automount
    h) HDMI CEC

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_general_config ;;
        2) fn_swap ;;
        3) fn_setup_steam ;;
        4) fn_base_apps ;;
        6) fn_code_development_apps ;;
        7) fn_media_development_apps ;;
        a) fn_automount;;
        h) fn_cec ;;
        *) $SHELL ;;
    esac
    done
}


function fn_automount {
    echo "Enter drive label to automount: "
    read drive_label
    
# mount
sudo tee /etc/systemd/system/mnt-${drive_label}.mount > /dev/null << EOL 
    [Unit]
    Description=automount of ${drive_label}

    [Mount]
    What=LABEL=${drive_label}
    Where=/mnt/${drive_label}/
    Options=noauto,nofail
    TimeoutSec=2
    ForceUnmount=true

    [Install]
    WantedBy=multi-user.target
EOL

# autmount
sudo tee /etc/systemd/system/mnt-${drive_label}.automount > /dev/null << EOL   
    [Unit]
    Description=automount of ${drive_label}

    [Automount]
    Where=/mnt/${drive_label}/
    TimeoutIdleSec=1800

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-${drive_label}.automount
    sudo systemctl restart mnt-${drive_label}.automount
}


function fn_cec {
    # https://wiki.archlinux.org/index.php/Users_and_groups#User_management

    #ls -l /dev/ttyUSB0
    #id -Gn
    #stat /dev/ttyACM0 <- should show which user group has access to device
    ./util.sh -i libcec
    
    USER=$(id -un)
    sudo gpasswd -a $USER uucp 
    sudo gpasswd -a $USER lock
    # might not need a reboot, test it
    getent group uucp

    notify-send 'CEC' 'Please reboot!'
}


function fn_setup_steam {
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


function fn_general_config {
    # disable broken kde search
    balooctl disable
    
    # fix systemd shutdown timeout
    sudo sed -i -e "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g" /etc/systemd/system.conf
    sudo sed -i -e "s/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g" /etc/systemd/system.conf
    
    # fix logs to be no more than 50mb
    sudo sed -i -e "s/#SystemMaxUse=/SystemMaxUse=50M/g"  /etc/systemd/journald.conf
    
    # setup pacman mirror
    echo "Local pacman mirror (http://pc:9129/repo/manjaro/$repo/os/$arch): "
    read mirror
    
sudo bash -c "cat > /etc/pacmand.d/mirrorlist" << EOL 
Server = ${mirror}
EOL
    
    notify-send 'Config' 'General config complete'
}


function fn_swap {
   # https://coreos.com/os/docs/latest/adding-swap.html
    # https://www.cyberciti.biz/faq/linux-add-a-swap-file-howto/
    # https://wiki.archlinux.org/index.php/Swap#Manually

    local_path=/swapfile
    #  ${string/regexp/replacement}
    swap_path_name="${local_path////-}"
    swap_path_name="${swap_path_name:1:${#swap_path_name}}"
    echo "Mounting: $local_path as $swap_path_name"
    
    # create 16gb swap
    # 1024bytes * 1024mb * xxxgb
    sudo swapoff -a
    
    echo "How much swap in GB (eg 16 = 16GB): "
    read swap_size
    
    # btrfs specific
    sudo truncate -s 0 $local_path
    sudo chattr +C $local_path
    sudo btrfs property set $local_path compression none
    
    sudo fallocate -l ${swap_size}G $local_path
    #sudo dd if=/dev/zero of=$local_path bs=1M count=8000
    #sudo chown root:root /swapfile
    sudo chmod 0600 $local_path

    # make swap and turn it on
    sudo mkswap $local_path
    sudo swapon $local_path

sudo bash -c "cat > /etc/systemd/system/$swap_path_name.swap" << EOL 
    [Unit]
    Description=mount swap

    [Swap]
    What=$local_path

    [Install]
    WantedBy=multi-user.target
EOL

    # adjust swappiness here?
    
    # enable swap
    sudo systemctl enable $swap_path_name.swap

    # show status
    free -m
    #swapon
    
    notify-send 'Swap' 'Created'
}


function fn_base_apps {
    # remove old stuff
    #use pactree qt4 - to list packages dependancies
    echo -e '\n\nRemoving packages...'
    #./util.sh -r xterm manjaro-hello manjaro-application-utility octopi-notifier-frameworks octopi-cachecleaner octopi-repoeditor octopi calligra kget yakuake plasma-wayland-session python-xdg xorg-xrandr udftools

    # install software
    echo -e '\n\nInstalling packages...'
    ./util.sh -i base-devel openssh   plasma-browser-integration libreoffice firefox keepassxc
    
    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}

function fn_code_development_apps {
    echo -e '\n\nInstalling code development apps...'
    ./util.sh -i visual-studio-code-bin guitar

    # extras
    # barrier
    # sound-juicer smartgit riot-desktop openwmail-bin 
    # vidcutter xnviewmp avidemux trojita handbrake kube
    # nheko
    # nitroshare lanshare


    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}

function fn_media_development_apps {
    echo -e '\n\nInstalling media development apps...'
    ./util.sh -i blender audacity krita obs-studio inkscape handbrake

    # extras
    # barrier kdenlive
    # sound-juicer smartgit riot-desktop openwmail-bin 
    # vidcutter xnviewmp avidemux trojita handbrake kube
    # nheko
    # nitroshare lanshare


    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}


# pass all args
main "$@"
