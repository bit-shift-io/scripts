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
    1) Samba & pac-cache
    2) Backup service
    3) HDMI CEC
    4) MPD & DLNA
    5) Update downloader Service
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        1) fn_smb ;;
        2) fn_mount_backup ; fn_backup_service ;;
        3) fn_cec ;;
        4) fn_mpd ;;
        5) fn_update_service ;;
        *) $SHELL ;;
    esac
    done
}


function fn_mount_backup {
    # https://blog.tomecek.net/post/automount-with-systemd/
    
# mount
sudo tee /etc/systemd/system/mnt-backup.mount > /dev/null << EOL 
    [Unit]
    Description=backup mount

    [Mount]
    What=LABEL=backup
    Where=/mnt/backup/
    Options=noauto,nofail
    TimeoutSec=2
    ForceUnmount=true

    [Install]
    WantedBy=multi-user.target
EOL

# autmount
sudo tee /etc/systemd/system/mnt-backup.automount > /dev/null << EOL   
    [Unit]
    Description=backup mount

    [Automount]
    Where=/mnt/backup/
    TimeoutIdleSec=60

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-backup.automount
    sudo systemctl start mnt-backup.automount

}


function fn_backup_service {
    sudo pacman --noconfirm -S borg python-llfuse

    # daily backup
sudo tee /etc/systemd/system/tool-backup-borg.service > /dev/null << EOL
    [Unit]
    Description=Backup Service

    [Service]
    ExecStart=/home/s/Scripts/tools.sh fn_backup_borg
EOL

sudo tee /etc/systemd/system/tool-backup-borg.timer > /dev/null << EOL 
    [Unit]
    Description=Daily backup

    [Timer]
    OnCalendar=daily
    Persistent=true   
    Unit=tool-backup-borg.service

    [Install]
    WantedBy=timers.target
EOL

    # Start timer, as root
    sudo systemctl start tool-backup-borg.timer

    # Enable timer to start at boot
    sudo systemctl enable tool-backup-borg.timer

    # list timers
    #systemctl list-timers

    notify-send "Backup Schedule" "Booked in!"
}


function fn_update_service {
    # daily download only
sudo tee /etc/systemd/system/tool-update.service > /dev/null << EOL
    [Unit]
    Description=Update Download Service

    [Service]
    ExecStart=/bin/pacman -Syuw
EOL

sudo tee /etc/systemd/system/tool-update.timer > /dev/null << EOL 
    [Unit]
    Description=Daily 4am download

    [Timer]
    OnCalendar=*-*-* 04:00:00
    Persistent=true   
    Unit=tool-update.service

    [Install]
    WantedBy=timers.target
EOL
    # Start timer, as root
    sudo systemctl start tool-update.timer

    # Enable timer to start at boot
    sudo systemctl enable tool-update.timer

    # list timers
    #systemctl list-timers

    notify-send "Backup Schedule" "Booked in!"
}


function fn_smb {
    # bellow here configures samaba for windows users
    sudo systemctl stop smb nmb

    #sudo rm -f /etc/samba/smb.conf

    # (> = overwite, >> = append)
sudo tee /etc/samba/smb.conf > /dev/null << EOL
    [global]
        workgroup = WORKGROUP
        netbios name = s
        server string = Samba Server
        
        name resolve order = lmhosts bcast host wins
        wins support = yes
        
        # automatic printer setup
        #printcap name = /etc/printcap
        printcap name = cups
        load printers = yes    
        
        security = user
        null passwords = true
        
        force user = s
        force group = s
        #force create mode
        #force directory mode
        create mask = 0755
        directory mask = 0755    
        
        guest account = nobody
        map to guest = Bad User
        guest ok = yes
        browsable = yes
        public = yes

    # read + write
    [Downloads]
        comment = Public
        path = /home/s/Downloads
        writeable = yes

    # read only
    [Games]
        comment = Public
        path = /home/s/Games
        read only = yes
        writeable = no	
        
    [Bible]
        comment = Public
        path = /home/s/Bible
        read only = yes
        writeable = no	
        
    [Music]
        comment = Public
        path = /home/s/Music
        read only = yes
        writeable = no		
        
    [s]
        comment = Private
        path = /home/s
        writeable = yes
        valid users = bronson, fabian
        
    [pacman]
        comment = Private
        path = /var/cache/pacman/pkg
        create mask = 0755
        force user = root
        writeable = yes
        valid users = bronson, fabian        
EOL

    # add users
    echo "Configure Bronson..."
    sudo useradd -r -s /usr/bin/nologin bronson
    sudo smbpasswd -a bronson

    echo "Configure Fabian..."
    sudo useradd -r -s /usr/bin/nologin fabian
    sudo smbpasswd -a fabian

    #enable and start
    sudo systemctl enable smb nmb
    sudo systemctl restart smb nmb

    notify-send 'SMB' 'Mount up!'
}

function fn_cec {
    # https://wiki.archlinux.org/index.php/Users_and_groups#User_management

    #ls -l /dev/ttyUSB0
    #id -Gn
    #stat /dev/ttyACM0 <- should show which user group has access to device
    yay -S --noconfirm --needed libcec
    
    USER=$(id -un)
    sudo gpasswd -a $USER uucp 
    sudo gpasswd -a $USER lock
    # might not need a reboot, test it
    getent group uucp

    notify-send 'CEC' 'Please reboot!'
}


function fn_mpd {
    ID_NAME=$(id -nu)

    yay -S --noconfirm alsa-utils ffmpeg mpd upmpdcli 
    # ncmpcpp 

    # setup library links
    mkdir ~/.config/mpd
    #ln -s $HOME/Bible ${HOME}/Music/Bible
    
    # mpd config
sudo tee /etc/mpd.conf > /dev/null << EOL       
    music_directory         "~/Music"
    playlist_directory      "~/Music/Playlists"
    db_file                 "~/.config/mpd/mpd.db"
    pid_file                "~/.config/mpd/mpd.pid"
    state_file              "~/.config/mpd/mpdstate"
    sticker_file            "~/.config/mpd/sticker.sql"
    log_file                "syslog"
    
    user                    "${ID_NAME}"
    
    bind_to_address         "any"
    port                    "6600"
    
    restore_paused          "yes"
    metadata_to_use         "artist,album,title,track,name,genre,date,composer,performer,disc"
    auto_update             "yes"
    follow_outside_symlinks "yes"
    follow_inside_symlinks  "yes"
    
    save_absolute_paths_in_playlists    "no"
    
    #replaygain              "track"
    #replaygain_preamp       "0"
    volume_normalization    "yes"
    
    zeroconf_enabled        "yes"
    zeroconf_name           "Music Player"
    
    audio_output {
        type                "alsa"
        name                "ALSA Output"
        device              "hw:0,0"        # optional
        #format             "44100:16:2"    # optional
        #mixer_device       "default"       # optional
        #mixer_control      "PCM"           # optional
        #mixer_index        "0"             # optional
        mixer_type          "software"      # optional
    }
    
    audio_output {
        type                "pulse"
        name                "PulseAudio Output"
        mixer_type          "software"    
    }
    
    audio_output {
        type                "httpd"
        name                "HTTP Stream"
        encoder             "vorbis"  # optional, vorbis or lame
        port                "8080"
        quality             "5.0"   # do not define if bitrate is defined
        # bitrate           "128"   # do not define if quality is defined
        format              "44100:16:1"
        max_clients         "0"   # optional 0=no limit
    }    
EOL

    # change user
    # https://unix.stackexchange.com/questions/64914/mpd-no-audio-output-with-pulseaudio-no-mixing-with-alsa
    sudo sed -i -e "s/User=mpd/User=${ID_NAME}\nPAMName=system-local-login/g" /usr/lib/systemd/system/mpd.service
    
    sudo systemctl daemon-reload
    sudo systemctl enable mpd
    sudo systemctl restart mpd
    
    # start upmpdcli as service
sudo tee /etc/systemd/system/dlna.service > /dev/null << EOL    
    [Unit]
    Description=DLNA service

    [Service]
    ExecStart=/usr/bin/upmpdcli
    
    [Install]
    WantedBy=default.target
EOL

    # change name
    
    sudo sed -i -e "s/#friendlyname = UpMpd/friendlyname = S/g" /usr/lib/systemd/system/mpd.service
    
    sudo systemctl enable dlna
    sudo systemctl restart dlna
    
    # configure sound
    # https://raspberrypi.stackexchange.com/questions/56278/possible-to-route-audio-directly-from-usb-audio-line-in-to-same-usb-audio-line-o
    # https://linux.die.net/man/1/alsaloop
    # https://stackoverflow.com/questions/43319199/how-to-loop-back-the-microphone-entry-directly-to-speakers-on-linux/43319706
    # enable audio loop backup
    # -C - capture device
    # -P - playback device
    # aplay -l and arecord-l
    #alsaloop -C hw:0,0 -P hw:0,0 -t 50000
    #arecord -Dplughw:<card_number>,<device_num>
    #arecord -Dhw:0,0 -f S16_LE -c 1 -r 48000 | aplay -Dhw:0,0 -f dat
    #arecord - | aplay -
    
    
    # airplay
    #https://www.lesbonscomptes.com/pages/raspmpd-details.html#upmpdcli
    #shairplay-sync - airplay
}


# pass all args
main "$@"
