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
    1) General config (systemd timeout, kde index)
    2) Pacman mirror (pacoloco)
    3) Swap
    4) Steam
    
    apps
    ===================
    5) Base Apps
    6) Media Development Apps
    7) Chinese pinyin virtual keyboard support

    extras
    ===================
    a) Automount
    h) HDMI CEC
    b) audio bluetooth
    s) audio network server
    c) audio network client
    m) microcontroller - arduino

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        2) fn_pacman_mirror ;;
        1) fn_general_config ;;
        3) fn_swap ;;
        4) fn_setup_steam ;;
        5) fn_base_apps ;;
        6) fn_media_development_apps ;;
        a) fn_automount;;
        h) fn_cec ;;
        b) fn_audio_bluetooth ;;
        s) fn_audio_network_server ;;
        c) fn_audio_network_client ;;
        m) fn_microcontroller ;;
        7) fn_pinyin ;;
        *) $SHELL ;;
    esac
    done
}


function fn_pinyin {
    # https://forum.manjaro.org/t/chinese-language-support/115416/5
    ./util.sh -i adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts
    ./util.sh fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons manjaro-asian-input-support-fcitx5
}


function fn_microcontroller {
        sudo tee /etc/udev/rules.d/01-ttyusb.rules > /dev/null << EOL 
SUBSYSTEMS=="usb-serial", TAG+="uaccess"
EOL
    # load new uev rule
    udevadm control --reload
    udevadm trigger

    # install after permissions set
    ./util.sh -i yay
    ./util.sh -i arduino-ide-bin
}

function fn_audio_network_server {
    ./util.sh -i pipewire-zeroconf
    
    sudo systemctl enable avahi-daemon
    sudo systemctl start avahi-daemon


    sudo tee /etc/pipewire/pipewire-pulse.conf.d/50-network-party.conf > /dev/null << EOL 
context.exec = [
    { path = "pactl" args = "load-module module-native-protocol-tcp" }
    { path = "pactl" args = "load-module module-zeroconf-discover" }
    { path = "pactl" args = "load-module module-zeroconf-publish" }
]
EOL
}

function fn_audio_network_client {
    ./util.sh -i pipewire-zeroconf

    sudo systemctl enable avahi-daemon
    sudo systemctl start avahi-daemon

    #mkdir -p $HOME/.config/pipewire/pipewire.conf.d/

    # pw-cli load-module libpipewire-module-raop-discover 
    # PIPEWIRE_DEBUG=3 pw-cli -m load-module libpipewire-module-raop-discover
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1542

    sudo tee /etc/pipewire/pipewire.conf.d/raop-discover.conf > /dev/null << EOL 
context.modules = [
    {
        name = libpipewire-module-raop-discover
        args = { }
    }
]
EOL
}

function fn_audio_bluetooth {
    USER=$(id -un)

    echo "Enter visible bluetooth name: "
    read bluetooth_name

    #echo "Enter bluetooth pin (eg 123456): "
    #read bluetooth_pin

    #./util.sh -i bluez bluez-utils bluez-tools
    ./util.sh -i python-dbus

    # bluetooth config
    # double qoutes to expand variable
    sudo sed -i "s/.*Name =.*/Name = ${bluetooth_name}/" /etc/bluetooth/main.conf 
    sudo sed -i 's/#DiscoverableTimeout = 0/DiscoverableTimeout = 0/' /etc/bluetooth/main.conf
    sudo sed -i 's/#AlwaysPairable = false/AlwaysPairable = true/' /etc/bluetooth/main.conf
    sudo sed -i 's/#PairableTimeout = 0/PairableTimeout = 0/' /etc/bluetooth/main.conf
    sudo sed -i 's/#JustWorksRepairing.*/JustWorksRepairing = always/' /etc/bluetooth/main.conf
    sudo sed -i 's/#AutoEnable=true/AutoEnable=true/' /etc/bluetooth/main.conf

    # might need one of the following?
    # sudo hciconfig hci0 sspmode 0
    # sudo hciconfig hci0 sspmode 1
    #sudo hciconfig hci0 noauth

#/etc/systemd/system/
sudo tee /usr/lib/systemd/user/bt.service > /dev/null << EOL 
[Unit]
Description=Bluetooth speaker agent
After=network.target bluetooth.service dbus.service

[Service]
TimeoutStartSec=60
ExecStartPre=/usr/bin/sleep 20
Environment=PYTHONUNBUFFERED=1
ExecStart=python ${HOME}/Projects/scripts/services/speaker-agent.py
#User=${USER}
#Group=${USER}

[Install]
WantedBy=default.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl --global enable bt.service
    sudo systemctl start bt.service
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


function fn_pacman_mirror {
    # setup pacman mirror
    echo "Local pacman mirror computer name/ip (eg: computer.local): "
    read computer_name

    echo "Local pacman mirror repo (manjaro or archlinux): "
    read repo_name

    # replace
    # Include = /etc/pacman.d/mirrorlist
    # with
    # Server = http://${computer_name}:9129/repo/${repo_name}/\$repo/\$arch
    # manjaro needs /os removed
    if [ $repo_name = 'manjaro' ]; then
        sudo sed -i "s,Include = /etc/pacman.d/mirrorlist,Server = http://${computer_name}:9129/repo/${repo_name}/\$repo/\$arch,g" /etc/pacman.conf
    else
        sudo sed -i "s,Include = /etc/pacman.d/mirrorlist,Server = http://${computer_name}:9129/repo/${repo_name}/\$repo/os/\$arch,g" /etc/pacman.conf
    fi
#sudo bash -c "cat > /etc/pacman.d/mirrorlist" << EOL
#Server = http://${computer_name}:9129/repo/${repo_name}/\$repo/\$arch
#EOL

    notify-send 'Config' 'Pacman cache updated'
}

function fn_general_config {
    # disable broken kde search
    balooctl disable
    
    # fix systemd shutdown timeout
    sudo sed -i -e "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g" /etc/systemd/system.conf
    sudo sed -i -e "s/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g" /etc/systemd/system.conf
    
    # fix logs to be no more than 50mb
    sudo sed -i -e "s/#SystemMaxUse=/SystemMaxUse=50M/g"  /etc/systemd/journald.conf

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
    ./util.sh -i base-devel openssh kio-extras  plasma-browser-integration libreoffice firefox keepassxc code git
    
    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}


function fn_media_development_apps {
    echo -e '\n\nInstalling media development apps...'
    ./util.sh -i blender audacity krita obs-studio inkscape handbrake

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}


# pass all args
main "$@"
