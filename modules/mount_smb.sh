#!/bin/bash


function add_mount {
    local_path=$1
    remote_path=$2
    smb_username=$3
    smb_password=$4
    local_user=$5

    id=""
    if $local_user; then
        mkdir -p $1
        uid=$(id -u)
        gid=$(id -g)
        id="uid=${uid},gid=${gid},forceuid,forcegid,"
    fi

    #  ${string/regexp/replacement}
    smb_path_name="${local_path////-}"
    smb_path_name="${smb_path_name:1:${#smb_path_name}}" # remove first, and last -2 to remove end ${smb_path_name:1:${#smb_path_name}-2}
    echo "Mounting: $local_path as $smb_path_name"
    
# credentials
sudo tee /etc/samba/smbcreds > /dev/null << EOL
username=$smb_username
password=$smb_password
EOL
sudo chmod 600 /etc/samba/smbcreds

# mount
sudo tee /etc/systemd/system/$smb_path_name.mount > /dev/null << EOL 
    [Unit]
    Description=smb mount
    Requires=network-online.target
    After=network-online.service
    Wants=network-online.target

    [Mount]
    What=$remote_path
    Where=$local_path
    #Options=${id}username=${smb_username},password=${smb_password},rw,_netdev,x-systemd.automount
    #Options=vers=2.1,credentials=/etc/samba/smbcreds,iocharset=utf8,rw,x-systemd.automount,uid=1000
    Options=${id}credentials=/etc/samba/smbcreds,iocharset=utf8,rw,x-systemd.automount
    Type=cifs
    TimeoutSec=2
    #ForceUnmount=true

    [Install]
    WantedBy=multi-user.target
EOL

    #sudo systemctl enable $smb_path_name.mount
    #sudo systemctl start $smb_path_name.mount


# autmount
sudo tee /etc/systemd/system/$smb_path_name.automount > /dev/null << EOL   
    [Unit]
    Description=smb mount

    [Automount]
    Where=$local_path
    TimeoutIdleSec=60

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable $smb_path_name.automount
    sudo systemctl start $smb_path_name.automount
}


## ==== MAIN CODE ====

echo "Enter smb username: "
read smb_user

echo "Enter smb password: "
read smb_pass

echo "Folder name: "
read dir_name

# camera as local user
local_path="$HOME/$dir_name"
remote_path="//living.lan/$dir_name"
add_mount $local_path $remote_path $smb_user $smb_pass true

# display list of mounts
systemctl list-units --type=automount
systemctl list-units --type=mount

notify-send 'Mount' 'Mount Completed'

