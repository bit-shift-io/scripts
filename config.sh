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
    3) Swap

    extras
    ===================
    h) HDMI CEC
    b) audio bluetooth
    s) audio network server
    c) audio network client
    m) microcontroller udev rules


    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_general_config ;;
        3) fn_swap ;;
        h) fn_cec ;;
        b) fn_audio_bluetooth ;;
        s) fn_audio_network_server ;;
        c) fn_audio_network_client ;;
        m) fn_microcontroller ;;
        *) $SHELL ;;
    esac
    done
}

function fn_microcontroller {
# arduino
sudo tee /etc/udev/rules.d/01-ttyusb.rules > /dev/null << EOL
SUBSYSTEMS=="usb-serial", TAG+="uaccess"
EOL

# NRF
sudo tee /etc/udev/rules.d/71-nrf.rules > /dev/null << EOL
ACTION!="add", SUBSYSTEM!="usb_device", GOTO="nrf_rules_end"

# Set /dev/bus/usb/*/* as read-write for all users (0666) for Nordic Semiconductor devices
SUBSYSTEM=="usb", ATTRS{idVendor}=="1915", MODE="0666"

# Flag USB CDC ACM devices, handled later in 99-mm-nrf-blacklist.rules
# Set USB CDC ACM devnodes as read-write for all users
KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1915", MODE="0666", ENV{NRF_CDC_ACM}="1"

LABEL="nrf_rules_end"
EOL

# NRF
sudo tee /etc/udev/rules.d/99-mm-nrf-blacklist.rules > /dev/null << EOL
# 99-modemmmanager-acm-fix.rules
# Previously flagged nRF USB CDC ACM devices shall be ignored by ModemManager
ENV{NRF_CDC_ACM}=="1", ENV{ID_MM_CANDIDATE}="0", ENV{ID_MM_DEVICE_IGNORE}="1"
EOL

    # load new uev rule
    udevadm control --reload
    udevadm trigger

    # install after permissions set
    #./util.sh -i yay
    #./util.sh -i arduino-ide-bin
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



function fn_general_config {
    # fix systemd shutdown timeout
    sudo sed -i -e "s/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g" /etc/systemd/system.conf
    sudo sed -i -e "s/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g" /etc/systemd/system.conf

    # fix logs to be no more than 50mb
    sudo sed -i -e "s/#SystemMaxUse=/SystemMaxUse=50M/g"  /etc/systemd/journald.conf

    # disable broken kde search
    balooctl disable

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


# pass all args
main "$@"
