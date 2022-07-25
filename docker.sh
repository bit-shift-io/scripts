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
    docker tools
    ===================
    d) Docker Base
    n) NextCloud Docker
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        d) fn_docker_base ;;
        n) fn_nextcloud ;;
        *) $SHELL ;;
    esac
    done
}

function fn_docker_base {
    ./util.sh -i docker docker-compose
    sudo systemctl enable docker
    sudo systemctl start docker
}

function fn_nextcloud {
    # https://hub.docker.com/_/nextcloud/
    # https://blog.ssdnodes.com/blog/installing-nextcloud-docker/
    # https://github.com/ichiTechs/Dockerized-SSL-NextCloud-with-MariaDB/blob/master/docker-compose.yml

    sudo docker network create nextcloud_network
    docker-compose up -f nextcloud-dockcer-compose.yml
}


# pass all args
main "$@"
