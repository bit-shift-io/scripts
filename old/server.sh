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
    a) automount
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        a) fn_mount_backup ;;
        *) $SHELL ;;
    esac
    done
}



function fn_mount_backup {
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



# pass all args
main "$@"
