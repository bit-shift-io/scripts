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
    dietpi config
    ===================
    a) install amd drivers
    h) set hostname
    b) bluetooth speaker

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        a) fn_amd_driver ;;
        h) fn_hostname ;;
        b) fn_bluetooth_speaker ;;

        *) $SHELL ;;
    esac
    done
}


function fn_bluetooth_speaker {
    sudo apt update
    sudo apt install -y bluez-alsa-utils bluez-tools

# udev rule to block other ble adapter
# Only disable the device physically plugged into Bus 1, Port 8 (doesnt have a serial id)
sudo tee "/etc/udev/rules.d/81-bluetooth-mask.rules" > /dev/null << EOL
SUBSYSTEM=="usb", KERNELS=="1-8", ATTR{authorized}="0"
EOL
sudo udevadm control --reload-rules
sudo udevadm trigger

# Create the Player (Pipes BT audio to your speakers)
sudo tee /etc/systemd/system/bluealsa-aplay.service > /dev/null << EOL
[Unit]
Description=BlueALSA-Aplay Player
After=bluealsa.service
Requires=bluealsa.service

[Service]
ExecStart=/usr/bin/bluealsa-aplay 00:00:00:00:00:00
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Create the Auth Agent (Automatically accepts pairing)
# NoInputNoOutput doesnt work?
sudo tee /etc/systemd/system/bt-agent.service > /dev/null << EOL
[Unit]
Description=Bluetooth Auth Agent
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/bt-agent -c DisplayOnly
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

    # 5. Reload and Start everything
    sudo systemctl daemon-reload
    sudo systemctl enable --now bluealsa bt-agent bluealsa-aplay

    sleep 2 # Give udev and services a moment to settle
    sudo rfkill unblock bluetooth
    sudo hciconfig hci0 up

    # Set Bluetooth
    echo "Configuring adapter as a Speaker..."
    sudo hciconfig hci0 class 0x240428
    sudo hciconfig hci0 sspmode 1

    sudo bluetoothctl power on
    sudo bluetoothctl discoverable on
    sudo bluetoothctl pairable on

    echo "Done!"
}


function fn_amd_driver {
    sudo apt update
    sudo apt install firmware-amd-graphics libgl1-mesa-dri
    lsmod | grep amdgpu
    echo "reboot now!"
}


# pass all args
main "$@"
