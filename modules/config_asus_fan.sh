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
    asus fan control
    ===================
    1) Read State
    
    set fans
    ===================
    q) Quiet
    s) Standard (default)
    h) High
    m) Max

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_read_state ;;
        q) fn_set_state 1 ;;
        s) fn_set_state 0 ;;
        h) fn_set_state 2 ;;
        m) fn_set_state 3 ;;
        *) $SHELL ;;
    esac
    done
}


function fn_read_state {
    state=$(sudo -i -u root bash << EOF
cd /sys/kernel/debug/asus-nb-wmi
echo 0x110019 > dev_id
cat ctrl_param
EOF
    )
    
    case $state in
        0x00000000)
            echo "Current fan state: Standard (0)"
            ;;
        0x00000001)
            echo "Current fan state: Quiet (1)"
            ;;
        0x00000002)
            echo "Current fan state: High-Performance (2)"
            ;;
        0x00000003)
            echo "Current fan state: Full-Performance (3)"
            ;;
        *)
            echo "Current fan state: Unknown ($state)"
            ;;
    esac
}


function fn_set_state {
    local state_value

    case $1 in
        0|standard)
            state_value=0
            ;;
        1|quiet)
            state_value=1
            ;;
        2|high)
            state_value=2
            ;;
        3|full)
            state_value=3
            ;;
        *)
            echo "Error: Invalid fan state. Use 0-3 or standard/quiet/high/full."
            exit 1
            ;;
    esac

    echo "Setting fan state to $state_value"
    sudo -i -u root bash << EOF
cd /sys/kernel/debug/asus-nb-wmi
echo 0x110019 > dev_id
echo $state_value > ctrl_param
cat devs
EOF
}


# pass all args
main "$@"
