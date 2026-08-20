#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

function main {
    # loop args
    if [[ $# -ne 0 ]] ; then
        for var in "$@" ; do
            $var
        done
        exit 1
    fi

    # menu
    while true; do
    read -n 1 -p "
    audio network
    ===================
    c) Client
    s) Server

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        c) fn_client ;;
        s) fn_server ;;
        *) $SHELL ;;
    esac
    done
}

function fn_setup_common {
    "$UTIL" -i pipewire-zeroconf

    sudo systemctl enable avahi-daemon
    sudo systemctl start avahi-daemon
}

function fn_client {
    fn_setup_common

    sudo tee /etc/pipewire/pipewire.conf.d/raop-discover.conf > /dev/null << EOL
context.modules = [
    {
        name = libpipewire-module-raop-discover
        args = { }
    }
]
EOL
}

function fn_server {
    fn_setup_common

    sudo tee /etc/pipewire/pipewire-pulse.conf.d/50-network-party.conf > /dev/null << EOL
context.exec = [
    { path = "pactl" args = "load-module module-native-protocol-tcp" }
    { path = "pactl" args = "load-module module-zeroconf-discover" }
    { path = "pactl" args = "load-module module-zeroconf-publish" }
]
EOL
}

# pass all args
main "$@"