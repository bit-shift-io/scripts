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
    3) Inspiron (wacom)
    4) Normalize Audio Output
    5) Disable Intel Audio
    6) General config (systemd timeout, kde index)
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_network_mount ;;
        2) fn_swap ;;      
        3) fn_inspiron ;;  
        4) fn_normalize_pulse_audio ;;
        5) fn_disable_intel_audio ;;
        6) fn_general_config ;; 
        *) $SHELL ;;
    esac
    done
}

function fn_general_config {
    # disable broken kde search
    balooctl disable
    
    # fix systemd shutdown timeout
    sudo sed -i -e "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g" /etc/systemd/system.conf
    sudo sed -i -e "s/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g" /etc/systemd/system.conf
    
    # fix logs to be no more than 50mb
    sudo sed -i -e "s/#SystemMaxUse=/SystemMaxUse=50M/g"  /etc/systemd/journald.conf

    notify-send 'Reboot' 'Audio disabled'
}

function fn_disable_intel_audio {
    cat /proc/asound/modules
    
sudo bash -c "cat > /etc/modprobe.d/blacklist" << EOL 
    blacklist snd_hda_intel
EOL

    notify-send 'Reboot' 'Audio disabled'
}


function fn_normalize_pulse_audio {
    yay -S --noconfirm swh-plugins

bash -c "cat > $HOME/.config/pulse/default.pa" << EOL 
    .nofail
    .include /etc/pulse/default.pa

    # Create compressed sink that outpus to the simultaneous output device
    load-module module-ladspa-sink  sink_name=ladspa_sink  master=combined plugin=dyson_compress_1403  label=dysonCompress  control=0,1,0.5,0.99

    # Create normalized sink that outputs to the compressed sink
    load-module module-ladspa-sink  sink_name=ladspa_normalized  master=ladspa_sink  plugin=fast_lookahead_limiter_1913  label=fastLookaheadLimiter  control=10,0,0.8

    # Comment out the line below to disable setting the normalized output by default:
    set-default-sink ladspa_normalized
EOL

    # restart audio
    pulseaudio -k
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
    local_path="$HOME/wine/cache"
    remote_path="//192.168.1.2/s/wine/cache"
    add_mount $local_path $remote_path $smb_username $smb_password true

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
        id="uid=${uid},gid=${gid},"
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
