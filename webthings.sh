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
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        1) fn_zigbee2mqtt ;;
        *) $SHELL ;;
    esac
    done
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
