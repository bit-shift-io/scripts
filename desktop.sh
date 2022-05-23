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
    desktop
    ===================
    1) General config (systemd timeout, kde index, manjaro database)
    2) Network Mount (optional, pac cache > server, wine cache)
    3) Steam
    4) Swap
    5) Base Apps
    6) Code Development Apps
    7) Media Development Apps

    mobile
    ===================
    m) Mobile Apps

    extras
    ===================
    v) Virtualbox
    g) Virtualbox Guest
    a) AMD GPU - fan fix

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_general_config ;;
        2) fn_network_mount ;;
        3) fn_setup_steam ;;
        4) fn_swap ;;
        5) fn_base_apps ;;
        6) fn_code_development_apps ;;
        7) fn_media_development_apps ;;
        m) fn_mobile_apps ;;
        v) fn_virtual_box ;;
        g) fn_virtual_box_guest ;;
        a) fn_amd_gpu ;;
        *) $SHELL ;;
    esac
    done
}


function fn_mobile_apps {
    # install software
    echo -e '\n\nInstalling packages...'
    
    # email, clock, calendar, calc, matrix, weather, browser, bible, music, mpd, map, dictionary, text editor, anbox, syncthing
    ./util.sh -i base-devel pamac yay openssh nota kdeconnect neochat vvave elisa plasma-camera plasma-pix filelight waydroid-image
    
    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    # waydroid
    pkexec setup-waydroid

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
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


    # add to top of mirror list and update
    # http://repo.manjaro.org/
    #sudo pacman-mirrors -c all # remove custom
    sudo pacman-mirrors --country Australia,New_Zealand,United_States
    
    # update database
    sudo pacman -Syy

    # aur helper
    sudo pacman -S yay --noconfirm --needed
    # sudo pacman -S pacui --noconfirm --needed # use pamac update instead now

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


function fn_network_mount {
    echo "Enter smb username: "
    read smb_username

    echo "Enter smb password: "
    read smb_password  
    
    # server
    local_path="/mnt/s"
    remote_path="//192.168.1.2/s"
    add_mount $local_path $remote_path $smb_username $smb_password false

    # pacman cache
    local_path="/var/cache/pacman/pkg"
    remote_path="//192.168.1.2/pacman"
    add_mount $local_path $remote_path $smb_username $smb_password false

    # wine cache
    # specify true for local user
    mkdir -p $HOME/wine/cache
    local_path="$HOME/wine/cache"
    remote_path="//192.168.1.2/s/wine/cache"
    add_mount $local_path $remote_path $smb_username $smb_password true
    
    # should be done in the mount above
    # permissions
    # get username
    #user=$(id -nu)
    #group=$(id -gn)
    #sudo chown ${user}:${group} ${local_path}

    # create ssh key
    cat /dev/zero | ssh-keygen -q -N ""
    ssh-copy-id s@192.168.1.2

    # display list of mounts
    systemctl list-units --type=automount
    systemctl list-units --type=mount

    notify-send 'Mount' 'Mount Completed'
}



function add_mount {
    local_path=$1
    remote_path=$2
    smb_username=$3
    smb_password=$4
    local_user=$5

    id=""
    if $local_user; then
        uid=$(id -u)
        gid=$(id -g)
        id="uid=${uid},gid=${gid},forceuid,forcegid,"
    fi

    #  ${string/regexp/replacement}
    smb_path_name="${local_path////-}"
    smb_path_name="${smb_path_name:1:${#smb_path_name}}" # remove first, and last -2 to remove end ${smb_path_name:1:${#smb_path_name}-2}
    echo "Mounting: $local_path as $smb_path_name"
    
# mount
sudo tee /etc/systemd/system/$smb_path_name.mount > /dev/null << EOL 
    [Unit]
    Description=cifs mount script
    Requires=network-online.target
    After=network-online.service
    Wants=network-online.target

    [Mount]
    What=$remote_path
    Where=$local_path
    Options=${id}username=${smb_username},password=${smb_password},rw,_netdev,x-systemd.automount
    Type=cifs
    TimeoutSec=2
    ForceUnmount=true

    [Install]
    WantedBy=multi-user.target
EOL

    #sudo systemctl enable $smb_path_name.mount
    #sudo systemctl start $smb_path_name.mount


# autmount
sudo tee /etc/systemd/system/$smb_path_name.automount > /dev/null << EOL   
    [Unit]
    Description=cifs mount script
    Requires=network-online.target
    After=network-online.service

    [Automount]
    Where=$local_path
    TimeoutIdleSec=60

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl enable $smb_path_name.automount
    sudo systemctl start $smb_path_name.automount
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
    ./util.sh -r xterm manjaro-hello manjaro-application-utility octopi-notifier-frameworks octopi-cachecleaner octopi-repoeditor octopi calligra kget yakuake plasma-wayland-session python-xdg xorg-xrandr udftools

    # install software
    echo -e '\n\nInstalling packages...'
    ./util.sh -i base-devel openssh falkon syncthing cantata plasma-browser-integration qbittorrent libreoffice firefox krdc krfb hunspell-en_AU keepassxc isoimagewriter
    
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


function fn_virtual_box {
    kernel=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')")
    yay -S --noconfirm $kernel-virtualbox-host-modules
    yay -S --noconfirm virtualbox virtualbox-ext-oracle
    sudo modprobe vboxdrv
    sudo usermod -aG vboxusers $USER
}

function fn_virtual_box_guest {
    # looks like we dont need this anymore as most of this should work out of the box
    #kernel=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')")
    #echo "kernel: ${kernel}"
    #yay -S --noconfirm --needed $kernel-headers
    #yay -S --noconfirm --needed xf86-video-vmware
    #yay -S --needed virtualbox-guest-utils # user input required, installs guest-modules also
    #echo "kernel: ${kernel}"

    # automount appears in /media/
    #sudo mkdir /media
    #sudo chown -R $USER:vboxsf /media
    #sudo chmod -R 755 /media
    sudo usermod -aG vboxsf $USER
    
    # autmount is now working, this is incase it breaks again
    '''
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
    '''
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
