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
    1) Base Apps
    2) Dev Apps
    3) Media Dev Apps
    4) Chinese pinyin virtual keyboard support

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_base_apps ;;
        2) fn_dev_apps ;;
        3) fn_media_development_apps ;;
        4) fn_pinyin ;;
        *) $SHELL ;;
    esac
    done
}

function fn_dev_apps {
    ./util.sh -i sourcegit-bin

}


function fn_pinyin {
    # https://forum.manjaro.org/t/chinese-language-support/115416/5
    ./util.sh -i adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts
    ./util.sh fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons manjaro-asian-input-support-fcitx5
}


function fn_base_apps {
    # remove old stuff
    # use pactree qt4 - to list packages dependancies
    #echo -e '\n\nRemoving packages...'
    #./util.sh -r kwrite

    # install software
    echo -e '\n\nInstalling packages...'
    ./util.sh -i yay base-devel openssh partitionmanager skanlite filelight kio-extras plasma-browser-integration libreoffice firefox keepassxc git rustup vulkan-radeon lib32-vulkan-radeon vulkan-intel sshfs isoimagewriter qbittorrent zed yakuake okular skanpage

    # printer support
    ./util.sh -i cups cups-pdf system-config-printer avahi
    sudo systemctl enable --now cups.service

    # aur software
    #echo -e '\n\nInstalling AUR packages...'
    #./util.sh -i visual-studio-code-bin

    # enable ssh
    sudo systemctl enable sshd.service
    sudo systemctl start sshd.service

    # enable bluetooth
    sudo systemctl enable bluetooth

    # disable firewall - endevour
    sudo systemctl stop firewalld
    sudo systemctl disable --now firewalld
    #sudo pacman -R firewalld

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}


function fn_media_development_apps {
    echo -e '\n\nInstalling media development apps...'
    ./util.sh -i blender audacity krita obs-studio inkscape handbrake pixieditor-bin

    echo -e '\n\ninstall complete'
    notify-send 'Applications' 'Install completed'
}


# pass all args
main "$@"
