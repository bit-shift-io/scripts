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
    1) Podman Install - Arch
    2) Podman Install - Debian/Arbmain
    r) Remove All Containers
    b) Backup podman folder
    u) Update containers
    p) Pipe Service
    *) Any key to exit
    :" ans;
    reset
    case $ans in 
        1) fn_install_arch ;;
        2) fn_install_debian ;;
        r) fn_remove_all ;;
        b) fn_backup ;;
        u) fn_update ;;
        p) fn_pipe ;;
        *) $SHELL ;;
    esac
    done
}



function fn_pipe {
    # pipe
    mkdir $HOME/Containers/pipe
    mkfifo $HOME/Containers/pipe/pipe_in
    mkfifo $HOME/Containers/pipe/pipe_out

# create script
sudo tee $HOME/Containers/pipe/start_pipe.sh > /dev/null << EOL
#!/bin/bash
while true; do eval "\$(cat pipe_in)" > pipe_out; done
EOL

# mount as /pipe in docker
sudo tee $HOME/Containers/pipe/run.sh > /dev/null << EOL
#!/bin/bash

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths relative to the script directory
PIPE_IN="$SCRIPT_DIR/pipe_in"
PIPE_OUT="$SCRIPT_DIR/pipe_out"

# Show script directory
echo "$SCRIPT_DIR"

# Echo arguments
echo "$@"

# Send to pipe_in
echo "$@" > "$PIPE_IN"

# Read from pipe_out
cat "$PIPE_OUT"
EOL

    sudo chmod +x $HOME/Containers/pipe/start_pipe.sh
    sudo chmod +x $HOME/Containers/pipe/run.sh

    # create service
sudo tee /etc/systemd/system/pipe.service > /dev/null << EOL
    [Unit]
    Description=container pipe
    After=sound.target

    [Service]
    ExecStart=$HOME/Containers/pipe/start_pipe.sh
    WorkingDirectory=$HOME/Containers/pipe/
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
    sudo systemctl start --now pipe 
    systemctl status pipe.service
}


function fn_update {
    echo "Pulling latest images for all running containers..."

    # Get all running container names and their images
    while read -r cname img; do
        echo "Processing container: $cname with image: $img"

        # Pull latest image
        podman pull --quiet "$img"

        # Stop the container's systemd service by removing systemd- prefix if present
        unit_base="${cname#systemd-}"
        echo "Stopping systemd service: $unit_base"
        systemctl --user stop "$unit_base"

        # Force remove the container
        echo "Removing container: $cname"
        podman rm -f "$cname"

        # Start the systemd service to recreate the container from updated image
        echo "Starting systemd service: $unit_base"
        systemctl --user start "$unit_base"

        echo "Updated and restarted $unit_base"
        echo
    done < <(podman ps --format "{{.Names}} {{.Image}}")

    echo "All running containers have been force updated."
}



function fn_backup {
    echo "backup docker folder..."
    hostname=$(hostname)
    archive=$HOME/Backups/podman-${hostname}.tar.gz
    backup=$HOME/Containers
    
    #echo "listing containers"
    #containers=$(docker container list -qa)
    #echo $containers

    mkdir $HOME/Backups

    echo "stop containers"
    podman pause --all

    echo "create backup..."
    echo ${archive}
    sudo tar -czvf ${archive} ${backup} > /dev/null

    echo "restart containers"
    podman unpause --all

    echo "done!"
}


function fn_install_debian {
    echo "todo"
}


function fn_install_arch {
    ./util.sh -i podman crun
    
    # podlet: need rust to compile, untile a bin version is released
    rustup default stable
    ./util.sh -i podlet # yay
    
    sudo systemctl start podman --now
}


function fn_remove_all {
    podman rm --all
    podman ps --all
}


# pass all args
main "$@"
