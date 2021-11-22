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
    server tools
    ===================
    1) zigbee2mqtt service
    2) adgaurd install
    3) webthings service
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        1) fn_zigbee2mqtt ;;
        2) fn_adguard ;;
        3) fn_webthings ;;
        *) $SHELL ;;
    esac
    done
}


function fn_webthings {
    # create service
sudo tee /etc/systemd/system/webthings.service > /dev/null << EOL
    [Unit]
    Description=webthings
    After=network.target

    [Service]
    ExecStart=/usr/bin/npm start
    WorkingDirectory=/home/pi/webthings/gateway
    StandardOutput=inherit
    StandardError=inherit
    Restart=always
    User=pi

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl reset-failed webthings
    sudo systemctl enable webthings
    sudo systemctl start webthings
}

function fn_adguard {
    wget https://static.adguard.com/adguardhome/release/AdGuardHome_linux_arm.tar.gz
    tar xvf AdGuardHome_linux_arm.tar.gz
    rm AdGuardHome_linux_arm.tar.gz
    cd AdGuardHome
    sudo ./AdGuardHome -s install
}


function fn_zigbee2mqtt {
    # create service
sudo tee /etc/systemd/system/zigbee2mqtt.service > /dev/null << EOL
    [Unit]
    Description=zigbee2mqtt
    After=network.target

    [Service]
    ExecStart=/usr/bin/npm start
    WorkingDirectory=/home/pi/zigbee2mqtt
    StandardOutput=inherit
    StandardError=inherit
    Restart=always
    User=pi

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl reset-failed zigbee2mqtt
    sudo systemctl enable zigbee2mqtt
    sudo systemctl start zigbee2mqtt
}



# pass all args
main "$@"
