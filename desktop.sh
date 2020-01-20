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
    4) Network Mount
    5) General config (systemd timeout, kde index)
    6) Steam
    7) Swap
    8) Normalize Audio Output
    9) Disable Intel Audio
    q) Virtualbox
    w) Virtualbox Guest
    e) Inspiron (wacom)
    a) AMD GPU
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_manjaro_database ;;
        2) fn_base_apps ;;
        3) fn_extra_apps ;;
        4) fn_network_mount ;;
        5) fn_general_config ;;
        6) fn_setup_steam ;;
        7) fn_swap ;;
        8) fn_normalize_pulse_audio ;;
        9) fn_disable_intel_audio ;;
        q) fn_virtual_box ;;
        w) fn_virtual_box_guest ;;
        e) fn_inspiron ;;
        a) fn_amd_gpu ;;
        *) $SHELL ;;
    esac
    done
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
    $SHELL
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
    # https://askubuntu.com/questions/95716/automatically-adjust-the-volume-based-on-content
    # note commented out alternative compressor
    ./util.sh -i swh-plugins

bash -c "cat > $HOME/.config/pulse/default.pa" << EOL 
    .nofail
    .include /etc/pulse/default.pa

    # Create compressed sink that outpus to the simultaneous output device
    load-module module-ladspa-sink  sink_name=ladspa_sink  master=combined plugin=sc4_1882 label=sc4  control=0,101.125,401,0,1,3.25,0
    #load-module module-ladspa-sink  sink_name=ladspa_sink  master=combined plugin=dyson_compress_1403  label=dysonCompress  control=0,1,0.5,0.99

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
    ./util.sh -i visual-studio-code-bin guitar blender audacity krita obs-studio inkscape barrier

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
