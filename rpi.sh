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
    4) route port 80 to 8080
    5) docker pipe
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        1) fn_zigbee2mqtt ;;
        2) fn_adguard ;;
        3) fn_webthings ;;
        4) fn_nftables ;;
        5) fn_dockerpipe ;;
        *) $SHELL ;;
    esac
    done
}

function fn_nftables {
    sudo systemctl --now enable nftables

sudo tee /etc/nftables.conf > /dev/null << EOL
#!/usr/bin/nft -f

flush ruleset

table inet filter {
        chain input {
                type filter hook input priority 0;
        }
        chain forward {
                type filter hook forward priority 0;
        }
        chain output {
                type filter hook output priority 0;
        }
}

table ip nat {
        chain prerouting {
                type nat hook prerouting priority 0; policy accept;
                tcp dport 80 redirect to 8080
        }

        chain postrouting {
                type nat hook postrouting priority 0; policy accept;
        }
}
EOL

    sudo nft -f /etc/nftables.conf
    #sudo systemctl restart nftables
    sudo nft list ruleset
}


function fn_dockerpipe {
    # pipe
    mkfifo /home/pi/Docker/pipe/pipe_in
    mkfifo /home/pi/Docker/pipe/pipe_out

    # create script
sudo tee /home/pi/Docker/pipe/start_pipe.sh > /dev/null << EOL
#!/bin/bash
while true; do eval "\$(cat pipe_in)" > pipe_out; done
EOL

sudo tee /home/pi/Docker/pipe/run.sh > /dev/null << EOL
#!/bin/bash
echo "\$@" > /pipe/pipe_in
cat /pipe/pipe_out
EOL

    sudo chmod +x /home/pi/Docker/pipe/start_pipe.sh
    sudo chmod +x /home/pi/Docker/pipe/run.sh

    # create service
sudo tee /etc/systemd/system/pipe.service > /dev/null << EOL
    [Unit]
    Description=docker pipe
    After=network.target

    [Service]
    ExecStart=/home/pi/Docker/pipe/start_pipe.sh
    WorkingDirectory=/home/pi/Docker/pipe/
    StandardOutput=inherit
    StandardError=inherit
    Restart=always
    User=pi

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl reset-failed pipe
    sudo systemctl enable pipe
    sudo systemctl start pipe
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
    cd $HOME
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
