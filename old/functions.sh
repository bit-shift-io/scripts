
function fn_network_mount {
    echo "Enter smb username: "
    read smb_username

    echo "Enter smb password: "
    read smb_password  
    
    # server
    local_path="/mnt/s"
    remote_path="//192.168.1.2/s"
    add_mount $local_path $remote_path $smb_username $smb_password false

    # pacman cache
    local_path="/var/cache/pacman/pkg"
    remote_path="//192.168.1.2/pacman"
    add_mount $local_path $remote_path $smb_username $smb_password false

    # wine cache
    # specify true for local user
    mkdir -p $HOME/wine/cache
    local_path="$HOME/wine/cache"
    remote_path="//192.168.1.2/s/wine/cache"
    add_mount $local_path $remote_path $smb_username $smb_password true
    
    # should be done in the mount above
    # permissions
    # get username
    #user=$(id -nu)
    #group=$(id -gn)
    #sudo chown ${user}:${group} ${local_path}

    # create ssh key
    cat /dev/zero | ssh-keygen -q -N ""
    ssh-copy-id s@192.168.1.2

    # display list of mounts
    systemctl list-units --type=automount
    systemctl list-units --type=mount

    notify-send 'Mount' 'Mount Completed'
}

function fn_amd_vsync {
    # script to fix tearing on AMD GPU's
    # https://wiki.archlinux.org/index.php/AMDGPU
sudo bash -c "cat > /etc/X11/xorg.conf.d/20-amdgpu.conf" << EOL 
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "TearFree" "true"
EndSection
EOL
}


function fn_virtual_box {
    kernel=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')")
    yay -S --noconfirm $kernel-virtualbox-host-modules
    yay -S --noconfirm virtualbox virtualbox-ext-oracle
    sudo modprobe vboxdrv
    sudo usermod -aG vboxusers $USER
}

function fn_virtual_box_guest {
    # looks like we dont need this anymore as most of this should work out of the box
    #kernel=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')")
    #echo "kernel: ${kernel}"
    #yay -S --noconfirm --needed $kernel-headers
    #yay -S --noconfirm --needed xf86-video-vmware
    #yay -S --needed virtualbox-guest-utils # user input required, installs guest-modules also
    #echo "kernel: ${kernel}"

    # automount appears in /media/
    #sudo mkdir /media
    #sudo chown -R $USER:vboxsf /media
    #sudo chmod -R 755 /media
    sudo usermod -aG vboxsf $USER
    
    # autmount is now working, this is incase it breaks again
    '''
    sudo modprobe -a vboxguest vboxsf vboxvideo
    sudo usermod -aG vboxsf $USER
    sudo systemctl enable vboxservice
    
    shares=$(sudo VBoxControl sharedfolder list | grep -Po "(?<=[0-9]{2} - ).*(?= \[id)")
    echo ""
    echo "Create automounts for:"
    echo "$shares"
    
    for share in ${shares[@]}; do
        create_vbox_mount ${share}
    done
    '''
}


function create_vbox_mount {
    sudo mkdir -p /mnt/vbox/${1}
    sudo chown -R $USER:vboxsf /mnt/vbox/${1}
    
# mount
sudo tee /etc/systemd/system/mnt-vbox-${1}.mount > /dev/null << EOL 
    [Unit]
    Description=vbox share

    [Mount]
    # vbox share name
    What=${1}
    Where=/mnt/vbox/${1}
    Options=noauto,nofail
    TimeoutSec=2
    ForceUnmount=true
    Type=vboxsf

    [Install]
    WantedBy=multi-user.target
EOL

# autmount
sudo tee /etc/systemd/system/mnt-vbox-${1}.automount > /dev/null << EOL   
    [Unit]
    Description=vbox share

    [Automount]
    Where=/mnt/vbox/${1}
    TimeoutIdleSec=60

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-vbox-${1}.automount
    sudo systemctl restart mnt-vbox-${1}.automount
}


function add_mount {
    local_path=$1
    remote_path=$2
    smb_username=$3
    smb_password=$4
    local_user=$5

    id=""
    if $local_user; then
        uid=$(id -u)
        gid=$(id -g)
        id="uid=${uid},gid=${gid},forceuid,forcegid,"
    fi

    #  ${string/regexp/replacement}
    smb_path_name="${local_path////-}"
    smb_path_name="${smb_path_name:1:${#smb_path_name}}" # remove first, and last -2 to remove end ${smb_path_name:1:${#smb_path_name}-2}
    echo "Mounting: $local_path as $smb_path_name"
    
# mount
sudo tee /etc/systemd/system/$smb_path_name.mount > /dev/null << EOL 
    [Unit]
    Description=cifs mount script
    Requires=network-online.target
    After=network-online.service
    Wants=network-online.target

    [Mount]
    What=$remote_path
    Where=$local_path
    Options=${id}username=${smb_username},password=${smb_password},rw,_netdev,x-systemd.automount
    Type=cifs
    TimeoutSec=2
    ForceUnmount=true

    [Install]
    WantedBy=multi-user.target
EOL

    #sudo systemctl enable $smb_path_name.mount
    #sudo systemctl start $smb_path_name.mount


# autmount
sudo tee /etc/systemd/system/$smb_path_name.automount > /dev/null << EOL   
    [Unit]
    Description=cifs mount script
    Requires=network-online.target
    After=network-online.service

    [Automount]
    Where=$local_path
    TimeoutIdleSec=60

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl enable $smb_path_name.automount
    sudo systemctl start $smb_path_name.automount
}


function fn_amd_gpu {
    yay -S --noconfirm radeon-profile-daemon-git radeon-profile-git
    sudo systemctl enable radeon-profile-daemon.service
    sudo systemctl start radeon-profile-daemon.service
}
