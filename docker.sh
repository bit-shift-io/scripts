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
    d) Docker Base
    r) Docker Remove All
    4) route port to 80
    5) docker pipe
    b) backup docker folder
    *) Any key to exit
    :" ans;
    reset
    case $ans in 
        d) fn_docker_base ;;
        r) fn_remove_all ;;
        4) fn_nftables ;;
        5) fn_dockerpipe ;;
        b) fn_backup ;;
        *) $SHELL ;;
    esac
    done
}

function fn_backup {
    hostname=$(hostname)
    archive=$HOME/Backups/docker-${hostname}.tar.gz
    backup=$HOME/Docker
    containers=$(docker container list -qa)

    mkdir $HOME/Backups

    echo "stop containers"
    sudo docker container stop ${containers}

    echo "create backup..."
    echo ${archive}
    sudo tar -czvf ${archive} ${backup} > /dev/null

    echo "restart containers"
    sudo docker restart ${containers}

    echo "done!"
}

function fn_nftables {
    echo "Enter port to forward to 80: "
    read port_forward

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
                tcp dport 80 redirect to ${port_forward}
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
    mkdir $HOME/Docker/pipe
    mkfifo $HOME/Docker/pipe/pipe_in
    mkfifo $HOME/Docker/pipe/pipe_out

    # create script
sudo tee $HOME/Docker/pipe/start_pipe.sh > /dev/null << EOL
#!/bin/bash
while true; do eval "\$(cat pipe_in)" > pipe_out; done
EOL

sudo tee $HOME/Docker/pipe/run.sh > /dev/null << EOL
#!/bin/bash
echo "\$@" > /pipe/pipe_in
cat /pipe/pipe_out
EOL

    sudo chmod +x $HOME/Docker/pipe/start_pipe.sh
    sudo chmod +x $HOME/Docker/pipe/run.sh

    # create service
sudo tee /etc/systemd/system/pipe.service > /dev/null << EOL
    [Unit]
    Description=docker pipe
    After=sound.target

    [Service]
    ExecStart=$HOME/Docker/pipe/start_pipe.sh
    WorkingDirectory=$HOME/Docker/pipe/
    StandardOutput=inherit
    StandardError=inherit
    Restart=always
    User=$USER
    Environment="PULSE_RUNTIME_PATH=/run/user/1000/pulse/"

    [Install]
    WantedBy=default.target
EOL

    sudo systemctl reset-failed pipe
    sudo systemctl enable pipe
    sudo systemctl start pipe
    systemctl status pipe.service
}


function fn_docker_base {
    ./util.sh -i docker docker-compose
    sudo systemctl enable docker
    sudo systemctl start docker
    # add user
    sudo usermod -aG docker ${USER}
}


function fn_remove_all {
    sudo docker container stop $(sudo docker container ls -aq)
    sudo docker container prune -f
    sudo docker ps
}


# pass all args
main "$@"
