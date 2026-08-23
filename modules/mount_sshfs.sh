#!/bin/bash

function add_mount {
    local_path=$1
    user=$2
    host=$3
    remote_path=$4
    
    uid=$(id -u)
    gid=$(id -g)

    # clean path name to the form home-user-path
    #  ${string/regexp/replacement}
    path_name="${local_path////-}"
    path_name="${path_name:1:${#path_name}}" # remove first, and last -2 to remove end ${smb_path_name:1:${#smb_path_name}-2}
    echo "Mounting: $local_path as $path_name"
    
# mount
sudo tee /etc/systemd/system/$path_name.mount > /dev/null << EOL 
    [Unit]
    Description=sshfs mount
    Before=remote-fs.target

    [Mount]
    What=$user@$host:$remote_path
    Where=$local_path
    Type=fuse.sshfs
    Options=_netdev,rw,nosuid,allow_other,uid=$uid,gid=$gid,default_permissions,follow_symlinks,idmap=user,reconnect,ServerAliveInterval=15,identityfile=$HOME/.ssh/id_ed25519,IdentitiesOnly=yes,UserKnownHostsFile=$HOME/.ssh/known_hosts,StrictHostKeyChecking=accept-new
    TimeoutSec=30

    [Install]
    WantedBy=remote-fs.target
    WantedBy=multi-user.target
EOL

    #sudo systemctl enable $smb_path_name.mount
    #sudo systemctl start $smb_path_name.mount


# autmount
sudo tee /etc/systemd/system/$path_name.automount > /dev/null << EOL   
    [Unit]
    Description=sshfs mount

    [Automount]
    Where=$local_path
    TimeoutIdleSec=0

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable $path_name.automount
    sudo systemctl restart $path_name.automount
}



# ensure an ssh key exists locally and is authorised on the remote box
function ensure_ssh_key {
    local dest=$1
    local key="$HOME/.ssh/id_ed25519"

    # generate the default key if missing
    if [[ ! -f "$key" ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -N "" -f "$key"
    fi

    # authorise it on the remote box if it isn't already
    if ! ssh -o BatchMode=yes -o IdentitiesOnly=yes -i "$key" -o ConnectTimeout=5 \
            "$dest" true 2> /dev/null; then
        echo "key not authorised on $dest yet, enter password when prompted:"
        ssh-copy-id -i "$key.pub" "$dest"
    fi
}

## ==== MAIN CODE ====

# allow other scripts to source this file and reuse add_mount
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

echo "Enter sftp user "
read remote_user

echo "Enter sftp host eg host.lan "
read remote_host

ensure_ssh_key "$remote_user@$remote_host"

echo "Enter sftp path eg: /home/s/dir "
read remote_path

echo "Enter local path eg: ${HOME}/path "
read local_path

add_mount $local_path $remote_user $remote_host $remote_path

# display list of mounts
systemctl list-units --type=automount
systemctl list-units --type=mount

notify-send 'Mount' 'Mount Completed'

# sshfs [user@]host:[remote_directory] mountpoint [options]

