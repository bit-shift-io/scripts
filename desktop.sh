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
    3) Code Development Apps
    0) Media Development Apps
    4) Network Mount
    5) General config (systemd timeout, kde index)
    6) Steam
    7) Swap
    8) Normalize Audio Output
    9) Disable HDMI Audio
    q) Virtualbox
    w) Virtualbox Guest
    e) Inspiron (wacom)
    m) Mitigations off
    a) AMD GPU
    p) Phone/Mobile Apps
    r) RTL-SDR tools
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_manjaro_database ;;
        2) fn_base_apps ;;
        3) fn_code_development_apps ;;
        0) fn_media_development_apps ;;
        4) fn_network_mount ;;
        5) fn_general_config ;;
        6) fn_setup_steam ;;
        7) fn_swap ;;
        8) fn_normalize_pulse_audio ;;
        9) fn_disable_audio ;;
        q) fn_virtual_box ;;
        w) fn_virtual_box_guest ;;
        e) fn_inspiron ;;
        m) fn_mitigations_off ;;
        a) fn_amd_gpu ;;
        p) fn_mobile_apps ;;
        r) fn_sdr ;;
        *) $SHELL ;;
    esac
    done
}


function fn_sdr {
    # https://ranous.files.wordpress.com/2020/05/rtl-sdr4linux_quickstartguidev20.pdf
    ./util.sh -i rtl-sdr gqrx cubicsdr rtl_433-git gnuradio
    rtl_test -s 2400000
    echo -e '\n\nrestart required'
    notify-send 'Applications' 'Please restart'
}


function fn_mobile_apps {
    # install software
    echo -e '\n\nInstalling packages...'
    ./util.sh -i openssh kate syncthing cantata kdeconnect okular marble vvave kcalc vlc
    
    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}

function fn_mitigations_off {
    # /etc/default/grub
    sudo sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet apparmor=1 security=apparmor udev.log_priority=3"/GRUB_CMDLINE_LINUX_DEFAULT="quiet apparmor=1 security=apparmor udev.log_priority=3 mitigations=off"/g' /etc/default/grub

    # finally update grub
    sudo update-grub

    notify-send 'Mitigations off' 'Reboot required'
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

    notify-send 'Reboot' 'Audio disabled'
}

function fn_disable_audio {
    cat /proc/asound/modules
    
sudo bash -c "cat > /etc/modprobe.d/blacklist.conf" << EOL 
    blacklist snd_hda_intel
    blacklist snd_hda_codec_hdmi
EOL

    notify-send 'Reboot' 'Audio disabled'
}


function fn_normalize_pulse_audio {
    # https://askubuntu.com/questions/95716/automatically-adjust-the-volume-based-on-content
    # https://unhexium.net/audio/uniform-audio-volume-with-pulseaudio/
    
    # http://plugin.org.uk/ladspa-swh/docs/ladspa-swh.html#tth_sEc2.91
    # SC4 1882 control info
    # The parameters (the control=1,1.5,401,-30,20,5,12 for example) for this compressor are described in Steve Harris' LADSPA Plugin Docs:
    # RMS/peak: The balance between the RMS and peak envelope followers. RMS is generally better for subtle, musical compression and peak is better for heavier, fast compression and percussion.
    # 9, Attack time (ms): The attack time in milliseconds.
    # 5, Release time (ms): The release time in milliseconds.
    # 63, Threshold level (dB): The point at which the compressor will start to kick in.
    # 6, Ratio (1:n): The gain reduction ratio used when the signal level exceeds the threshold.
    # -15, Knee radius (dB): The distance from the threshold where the knee curve starts.
    # 3, Makeup gain (dB): Controls the gain of the makeup input signal in dB's.
    # 49, Amplitude (dB): The level of the input signal, in decibels.
    # no value was placed here
    # Gain reduction (dB): The degree of gain reduction applied to the input signal, in decibels.
    
    
    # dyson compress
    # peak limit (db) (-30-0)
    # release time (s) (0-1)
    # fast compress ratio (0-1)
    # compress ratio (0-1)
    
    
    # http://plugin.org.uk/ladspa-swh/docs/ladspa-swh.html#tth_sEc2.39
    # This is a limiter with an attack time of 5ms. It adds just over 5ms of lantecy to the input signal, but it guatantees that there will be no signals over the limit, and tries to get the minimum ammount of distortion.
    # Input gain (dB): Gain that is applied to the input stage. Can be used to trim gain to bring it roughly under the limit or to push the signal against the limit.
    # Limit (dB): The maximum output amplitude. Peaks over this level will be attenuated as smoothly as possible to bring them as close as possible to this level.
    # Release time (s): The time taken for the limiters attenuation to return to 0 dB's
    # Attenuation (dB): The current attenuation of the signal coming out of the delay buffer. 
    
    # https://wiki.archlinux.org/index.php/PulseAudio#Audio_post-processing
    ./util.sh -i swh-plugins


bash -c "cat > $HOME/.config/pulse/default.pa" << EOL 
    .nofail
    .include /etc/pulse/default.pa
    load-module module-ladspa-sink  sink_name=ladspa_sink  master=combined plugin=sc4_1882 label=sc4  control=0,101.125,401,-22,10,3.25,0
    load-module module-ladspa-sink  sink_name=ladspa_normalized  master=ladspa_sink  plugin=fast_lookahead_limiter_1913  label=fastLookaheadLimiter  control=10,0,0.8
    set-default-sink ladspa_normalized
EOL

    # https://github.com/gotbletu/shownotes/blob/master/pulseaudio-dynamic-range-compression.md
bash -c "cat > $HOME/.config/pulse/default.pa" << EOL 
    .nofail
    .include /etc/pulse/default.pa
    load-module module-ladspa-sink sink_name=compressor-stereo plugin=sc4_1882 label=sc4 control=1,1.5,401,-30,20,5,12
    set-default-sink compressor-stereo
EOL


bash -c "cat > $HOME/.config/pulse/default.pa" << EOL 
    .nofail
    .include /etc/pulse/default.pa
    load-module module-ladspa-sink  sink_name=ladspa_sink  master=combined plugin=dyson_compress_1403  label=dysonCompress  control=-20,1,0.5,0.99
    load-module module-ladspa-sink  sink_name=ladspa_normalized  master=ladspa_sink  plugin=fast_lookahead_limiter_1913  label=fastLookaheadLimiter  control=10,0,0.8
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
    ./util.sh -r xterm manjaro-hello manjaro-application-utility octopi-notifier-frameworks octopi-cachecleaner octopi-repoeditor octopi calligra kget yakuake plasma-wayland-session python-xdg xorg-xrandr udftools pamac-tray-appindicator pamac-tray-icon-plasma
pamac-qt pamac-gtk pamac-cli pamac-snap-plugin pamac-flatpak-plugin pamac-common

    # install software
    echo -e '\n\nInstalling packages...'
    ./util.sh -i binutils make gcc pkg-config fakeroot openssh falkon syncthing cantata plasma-browser-integration qbittorrent libreoffice firefox thunderbird krdc krfb hunspell-en_AU ventoy keepassxc
    
    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}

function fn_code_development_apps {
    echo -e '\n\nInstalling code development apps...'
    ./util.sh -i visual-studio-code-bin guitar smartgit

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
