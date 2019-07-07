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
    1) Network Mount
    2) Swap
    3) Inspiron
    4) Mouse    
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_network_mount ;;
        2) fn_swap ;;      
        3) fn_inspiron ;;
        4) fn_mouse ;;            
        *) $SHELL ;;
    esac
    done
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
    
    sudo fallocate -l {$swap_size}G $local_path
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


function fn_inspiron {
    # helpful links:
    # https://wiki.archlinux.org/index.php/Tablet_PC


    yay -S --noconfirm --needed onboard # onscreen keyboard
    yay -S --noconfirm --needed xournal # note taking with stylus
    yay -S --noconfirm --needed cellwriter # hand writing recognition

    yay -S --noconfirm --needed iio-sensor-proxy-git kded-rotation-git # kde auto screen rotation

    yay -S --noconfirm --needed xf86-input-wacom # wacom tools


    # fix the right click on the track pad if its a problem

    #cat > "/usr/share/X11/xorg.conf.d/52-mymods.conf" << EOL
    #Section "InputClass"
    #Identifier "Force Clickpad Config"
    #MatchDriver "synaptics"
    #Option "ClickPad" "true"
    #Option "EmulateMidButtonTime" "0"
    #Option "SoftButtonAreas" "50% 0 82% 0 0 0 0 0"
    #Option "SecondarySoftButtonAreas" "58% 0 0 15% 42% 58% 0 15%"
    #EndSection 
    #EOL
}


function fn_network_mount {
    echo "Enter smb username: "
    read smb_username

    echo "Enter smb password: "
    read smb_password  
        
    local_path="/mnt/s"
    remote_path="//192.168.1.2/s"

    add_mount $local_path $remote_path $smb_username $smb_password


    local_path="/var/cache/pacman/pkg"
    remote_path="//192.168.1.2/pacman"

    add_mount $local_path $remote_path $smb_username $smb_password
        
    # create ssh key
    cat /dev/zero | ssh-keygen -q -N ""
    ssh-copy-id s@192.168.1.2

    notify-send 'Mount' 'Mount Completed'
}


function add_mount {
    local_path=$1
    remote_path=$2
    smb_username=$3
    smb_password=$4
 
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
    Options=username=$smb_username,password=$smb_password,rw,_netdev,x-systemd.automount
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



function fn_mouse {
    sudo pacman -S --noconfirm xorg-xinput

    # temp config for current session
    # https://stackoverflow.com/questions/18755967/how-to-make-a-program-that-finds-ids-of-xinput-devices-and-sets-xinput-some-set/18756948#18756948
    devlist=$(xinput --list | grep "USB Gaming Mouse" | sed -n 's/.*id=\([0-9]\+\).*/\1/p')
    for id in $devlist; do
        xinput set-prop $id "AccelProfile" "flat" #"Device Accel Velocity Scaling" 1
        xinput set-prop $id "AccelSpeed" "-0.8" #"Device Accel Constant Deceleration" 3
    done 

# (> = overwite, >> = append)
sudo bash -c 'cat > /etc/X11/xorg.conf.d/50-mouse.conf' << EOL
Section "InputClass"
    Identifier "My Mouse"
    MatchProduct "USB Gaming Mouse"
    Driver "libinput"
    MatchIsPointer "yes"
    Option "AccelProfile" "flat"
    Option "AccelSpeed" "-0.8"
EndSection
EOL

    notify-send 'Mouse' 'Settings applied'
}


# pass all args
main "$@"
