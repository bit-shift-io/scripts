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
    1) Speed test
    2) DVD to video
    3) DVD to ISO
    4) Sound Juicer
    5) mp3gain
    6) mp4gain
    7) Windows boot usb
    8) Borg Backup
    9) Gdrive Backup
    d) Duplicate database entry fix
    n) Test Network Routes
    l) Limit Bandwidth
    c) Chroot Ubuntu 14 LTS (Trusty)
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_speed_test ;;
        2) fn_dvd_to_video ;;      
        3) fn_dvd_to_iso ;;
        4) fn_sound_juicer ;;
        5) fn_mp3gain ;;
        6) fn_mp4gain ;;  
        7) fn_windows_usb ;;
        8) fn_backup_borg ;;
        9) fn_backup_gdrive ;;
        d) fn_duplicate_database_entry ;;
        n) fn_network_test ;;
        l) fn_limit_bandwidth ;;
        c) fn_chroot ;;
        *) $SHELL ;;
    esac
    done
}


function fn_chroot {
    # https://bbs.archlinux.org/viewtopic.php?id=100039
    
    ./util.sh -i debootstrap schroot
    
    # get username
    user=$(id -nu)
    
sudo bash -c "cat > /etc/schroot/schroot.conf" << EOL
[ubuntu]
description=Ubuntu
type=directory
directory=/var/chroot/ubuntu
users=${user}
root-users=${user}
aliases=trusty,default
EOL


sudo bash -c "cat > /etc/schroot/default/nssdatabases" << EOL
# System databases to copy into the chroot from the host system.
#
# <database name>
passwd
shadow
group
gshadow
services
protocols
#networks
hosts
EOL

    sudo debootstrap --arch amd64 trusty /var/chroot/ubuntu http://au.archive.ubuntu.com/ubuntu/
    
    # and login 
    schroot -u root -c ubuntu
}

function fn_duplicate_database_entry {
    # https://mayankjohri.wordpress.com/2014/10/06/tips-arch-linux-how-to-resolve-error-duplicated-database-entry-error-message/
    pac_dir="/var/lib/pacman/local"
    file_list=(${pac_dir}/*) # file to array
    last_package=""
    last_file=""

    # loop each file
    for file in ${file_list[@]}; do
        # get package name - first hyphen with a number after it
        package=$(echo "${file}" | sed 's/-[0-9].*//')

        # delete old file as it should be sorted alphabetically
        if [ "${package}" == "${last_package}" ]; then
            echo "delete: ${last_file}"
            sudo rm -rf ${last_file}
        fi

        last_package=${package}
        last_file=${file}
    done
}

function fn_network_test {
    routes=(
        "192.168.1.3,router",
        "10.104.4.101,roof-espy",
        "10.104.2.68,espy-gibbz",
        "10.104.2.66,espy-gateway",
        "10.104.0.227,gateway",
        "10.106.16.11,prospect",
    )

    for route in "${routes[@]}"; do
        split=(${route//,/ })
        
        result=$(ping -c1 ${split[0]} | grep -c 'Unreachable')
        if [ ${result} -eq "1" ]; then
            echo "${split[1]} ${split[0]} unreachable"
        else
            echo "${split[1]} ${split[0]} ok"
        fi
    done
}


function fn_limit_bandwidth {
    echo "Limit Download (kb/s 0=unlimited): "
    read limit_down
    
    if [ ${limit_down} == "0" ]; then
        sudo tc qdisc delete dev enp0s3 root
    else
        sudo tc qdisc add dev enp0s3 root tbf rate ${limit_down}kbit latency 42ms burst 2k
        #sudo tc qdisc add dev enp0s3 root tbf rate ${limit_down}mbit burst 32kbit latency 40ms
    fi
}

function fn_backup_borg {
    # RUN AS ROOT!
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
    export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

    DEST_ROOT="/mnt/backup"
    REPO="$DEST_ROOT/borg-backup"
    MNT="$DEST_ROOT/borg-mnt"

    # check if backup drive is mounted
    ls ${DEST_ROOT} # spin up drive for automount
    is_mounted=$(lsblk | grep ${DEST_ROOT} -c)
    if [ "${is_mounted}" == "0" ]; then
        notify-send -u critial 'Backup' 'Drive not mounted!'
        exit
    fi


    # unmount
    borg umount $MNT

    # unlock
    borg break-lock $REPO

    # create repo if it doesnt exist
    borg init --encryption=none $REPO

    # creat exclude file
cat >$DEST_ROOT/borg-exclude.txt <<EOF
    # Comment line
    /home/*/Downloads
    /home/*/Projects
    /home/*/Games/Steam
    /home/*/Trash
    /home/*/.cache
    /home/*/Applications
    lost+found
    .Trash*
    .stfolder
    .stversions
EOF

    # add dirs to reop
    borg create --stats --progress --exclude-from $DEST_ROOT/borg-exclude.txt --exclude-caches $REPO::'{hostname}-{now}' /home

    # prune older than
    borg prune -v --list --keep-daily=3 --keep-weekly=2 --keep-monthly=2 $REPO

    # mount the repo so we can easily access files
    # this only works until the filesystem is unmounted (sleep?)
    #sudo mkdir -p $MNT
    #sudo chown s:s $MNT
    #borg mount -o allow_other $REPO $MNT

    # output some log data
    borg info $REPO --last 1 | sudo tee $DEST_ROOT/borg-info.txt
    borg list $REPO | sudo tee $DEST_ROOT/borg-list.txt

    echo "done!"
}


function fn_backup_gdrive {
    echo "Zip password:"
    read pswd

    # install
    gdrive_installed=$(yay -Qm | grep "gdrive")
    if [ "$gdrive_installed" == "" ]; then
        echo "Installing required tools...."
        yay -S --noconfirm gdrive
        echo "Ensure 'gdrive list' functions correctly by allowing it access to your google account:"
        gdrive list
        echo "once gdrive has access to your google account, you can rerun this script to backup"
        notify-send 'Backup' 'Install of backup tools completed'
        exit
    fi

    echo "Backing up to google drive..."

    BACK_UP_DIR_NAME="Backup"
    BACK_UP_DIR_ID=$(gdrive list --absolute -q "name = '${BACK_UP_DIR_NAME}'" | grep "${BACK_UP_DIR_NAME} " | awk '{print $1}')

    echo "'${BACK_UP_DIR_NAME}' id is: ${BACK_UP_DIR_ID}"
    echo ""

    fn_zip_and_upload ~/scripts $pswd
    fn_zip_and_upload ~/Fabian/Documents $pswd
    # fn_zip_and_upload /home/s/atlassian # can we just backup the database?

    # go into GIT dir and zip each repo by itself
    DIRS=~/GIT/*
    for d in $DIRS
    do
    fn_zip_and_upload $d $pswd
    done

    notify-send 'Backup' 'Backup completed'
}


# $1 = dir to zip
function fn_zip_and_upload  {
    echo "Zip and upload: $1 $2"

    if [ ! -d "$1" ]; then
        echo "ERROR: dir does not exist: $1"
        return
    fi
    
    zip_filename=$(basename "$1").7z
    
    # zip dir
    echo "z a $1.7z $1 -p\"${2}\" -mhe=on"
    7z a $1.7z $1 -p"${2}" -mhe=on
    
    # delete old file
    echo "Looking for file on gdrive: ${BACK_UP_DIR_NAME}/${zip_filename}" 
    existing_file_id=$(gdrive list --absolute | grep "${BACK_UP_DIR_NAME}/${zip_filename} " | awk '{print $1}')
    echo "Existing file found on gdrive, id: ${existing_file_id}" 
    gdrive delete ${existing_file_id}
    
    # upload new zip
    echo "gdrive upload --parent ${BACK_UP_DIR_ID} $1.7z"
    gdrive upload --parent ${BACK_UP_DIR_ID} $1.7z

    # remove dir
    rm $1.7z
}



function fn_usb_multiboot {
    loop_dir=/media/loop
    usb_dir=/media/usb
    usb_label=Multiboot

    lsblk
    echo -n "Enter USB Device (ie /dev/sdc): " 
    read device

    # create dirs
    sudo mkdir $usb_dir

    # check if partition exists
    partition_exists=$(sudo partprobe -d -s ${device} | grep -c msdos)
    if [ ${partition_exists} -eq 0 ];then
        # partition
        sudo umount $device?* # unmount all partitions
        sudo dd if=/dev/zero of=$device seek=1 count=2047 # nuke old boot stuff

        # fat32
        sudo parted -s $device mklabel msdos mkpart primary fat32 1MiB 100% set 1 boot on print
        #sudo parted -s $device mklabel gpt mkpart P1 msdos 1MiB 100% name 1 ${usb_label} set 1 boot on print
    fi

    # mount
    sudo mkfs.msdos -F 32 ${device}1 -n ${usb_label}
    sudo mount -t vfat ${device}1 $usb_dir
        
    # install grub for bios boot
    sudo mkdir -p ${usb_dir}/EFI/BOOT
    sudo grub-install --force --removable --boot-directory=${usb_dir}/boot --efi-directory=${usb_dir}/EFI/BOOT ${device}
    sudo grub-install --force --target=i386-pc --boot-directory="${usb_dir}/boot" ${device}

    # (> = overwite, >> = append)
    sudo rm ${usb_dir}/boot/grub/grub.cfg
sudo bash -c "cat > ${usb_dir}/boot/grub/grub.cfg" << EOL
    set default="0"
    set timeout="30"
    set hidden_timeout_quiet=false
    set gfxmode=auto
    set root=(hd0)

    insmod part_gpt
    insmod chain
    insmod part_msdos
    insmod search_label
    insmod normal
    insmod linux
    insmod loopback
    insmod iso9660
    insmod fat        # If ISO is located on fat16 or fat32 formatted partition.
    insmod ntfs       # If ISO is located on an NTFS formatted partition.
    insmod nftscomp 
    
    #set pref=/EFI/boot

    # Load graphics (only corresponding ones will be found)
    # (U)EFI
    #insmod efi_gop
    #insmod efi_uga
    # legacy BIOS
    #insmod vbe

    menuentry "Manjaro Loopback.cfg" --class disk {
    isofile="/manjaro.iso"
    export isofile
    search --no-floppy -f --set=root \$isofile
    probe -u \$root --set=abc
    export abc
    loopback loop \$isofile
    root=(loop)
    configfile /boot/grub/loopback.cfg
    loopback --delete loop
    }

    menuentry "Manjaro" --class dvd {
    set isofile="/manjaro.iso"
    search --no-floppy -file --set=root \${isofile}
    probe -u \${root} --set=abc
    set idev="/dev/disk/by-uuid/\${abc}"
    loopback loop \${isofile}
    linux (loop)/boot/vmlinuz-x86_64 img_dev=\${idev} img_loop=\${isofile} driver=free tz=Europe/London lang=en_GB keytable=us
    initrd (loop)/boot/initramfs-x86_64.img
    }

    menuentry "Ubuntu" {
    set isofile="/ubuntu.iso"
    loopback loop ${isofile}
    set gfxpayload=keep 
    linux (loop)/casper/vmlinuz.efi file=(loop)/preseed/ubuntu.seed boot=casper iso-scan/filename=${isofile} quiet splash ---
    initrd (loop)/casper/initrd.lz
    }

    menuentry "Ubuntu Server" {
    set isofile="/ubuntu-server.iso"
    loopback loop ${isofile}
    set gfxpayload=keep
    linux (loop)/install/vmlinuz file=(loop)/preseed/ubuntu-server.seed iso-scan/filename=${isofile} quiet --
    initrd (loop)/install/initrd.gz
    }

    menuentry "Puppy" {
    set isofile="/puppy.iso"
    loopback loop \${isofile}
    linux (loop)/vmlinuz pfix=ram pmedia=cd iso-scan/filename=\${isofile}
    initrd (loop)/initrd.gz
    }

    menuentry "CloneZilla" {
    set root=(hd0)/clonezilla
    search --set-root=/clonezilla/ /clonezilla/boot/grub/grub.cfg
    configfile /clonezilla/boot/grub/grub.cfg
    }


    menuentry "CloneZilla 2" {
    search --set-root=/clonezilla/ /clonezilla/boot/grub/grub.cfg
    configfile /clonezilla/boot/grub/grub.cfg
    }


    menuentry "CloneZilla 3" {
    set root=(hd0)/clonezilla
    configfile /clonezilla/boot/grub/grub.cfg
    }

    menuentry "CloneZilla 4" {
    configfile /clonezilla/boot/grub/grub.cfg
    }


    menuentry "CloneZilla 5" {
    chainloader (hd0)/clonezilla
    boot
    }


    menuentry "CloneZilla 6" {
    chainloader (hd0)/clonezilla
    }


    menuentry "Windows" {
    insmod ntfs
    insmod search_label
    search --no-floppy --set=root --label ${usb_label} --hint hd0,msdos1
    ntldr /bootmgr
    boot
    }


    menuentry "HDD 1" {
    # insmod ntfs
    # insmod chain
    # insmod part_msdos
    # insmod part_gpt
    set root=(hd1)
    chainloader +1
    boot
    } 

    menuentry "Shutdown" {
        halt
    }
    menuentry "Reboot" {
        reboot
    }
EOL


    # cleanup
    sudo umount $usb_dir
    sudo rm -r $usb_dir

    notify-send 'USB' 'Completed'
}


function fn_performance {
    # display
    lscpu | grep MHz
    cat /proc/cpuinfo | grep "MHz"
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor


    # performance
    # cpu
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    # gpu
    # pacaur -S dpm-query
    # https://github.com/illwieckz/dpm-query
    #sudo dpm-query set all high performance


    # minimal
    echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor


    # default
    schedutil
}


function fn_repair_chroot {
    echo "chroot"
    lsblk
    sudo mount /dev/sda2 /mnt
    #sudo pacman -S manjaro-base-tools # mhwd-chroot
    sudo mhwd-chroot /mnt
}


function fn_repair_uefi {
    echo "efi"
    efibootmgr --verbose
    # efibootmgr --disk /dev/sda --part 2 --create --gpt --label "Arch Linux" --loader /vmlinuz-4.9-x86_64 --unicode "root=/dev/sda2 rw initrd=/initramfs-4.9-x86_64.img"
}


function fn_stream_device {
    v4l2-ctl --list-devices
    source=/dev/video0
    ffmpeg -f v4l2 -list_formats all -i ${source}
    
    # mjpeg rawvideo yuyv422
    

    # working laggy thou
    #ffmpeg -re -f v4l2 -input_format mjpeg -framerate 15 -video_size 864x480 -i ${source} -an -c:v libx264 -preset ultrafast -tune zerolatency -flush_packets 0 -f mpegts udp://224.0.0.1:9999?pkt_size=188&buffer_size=65535
    
    #ffmpeg -re -f v4l2 -input_format mjpeg -video_size 864x480 -i ${source} -an -c:v copy -f mjpeg udp://224.0.0.1:9999?pkt_size=131&buffer_size=65535
    
    #ffmpeg -re -f video4linux2 -s 864x480 -i ${source} -f mjpeg udp://224.0.0.1:9999?pkt_size=131&buffer_size=65535
    
    # no latency?
    #ffmpeg -re -f v4l2 -input_format mjpeg -video_size 864x480 -i ${source} -an -c:v mpeg2video -q:v 20 -pix_fmt yuv420p -g 1 -threads 2 -f mpegts udp://224.0.0.1:9999?pkt_size=131&buffer_size=65535
    
    ffmpeg -re -f v4l2 -input_format mjpeg -framerate 15 -video_size 864x480 -i ${source} -an -c:v libx264 -preset ultrafast -tune zerolatency -flush_packets 0 -f mpegts http://localhost:8090/feed1.ffm
}


function fn_stream_desktop {
    REC_iface=$(pactl list sources short | awk '{print$2}' | grep 'monitor')
    SCREEN_res=$(xrandr -q --current | grep '*' | awk '{print$1}')
    SCREEN2_res=$(xrandr -q --current | grep '*' | sed -n 2p | awk '{print$1}')

    echo $SCREEN_res
    echo "recording... press ctrl+c to end..."

    #-video_size $SCREEN_res

    #ffmpeg -f x11grab -framerate 24 -video_size $SCREEN_res -i :0.0+0,0 -c:v libx264 -g 50 -preset veryfast -pix_fmt yuv420p -s 1280:720 -f mpegts udp://224.0.0.1:9999?pkt_size=188&buffer_size=1024
    
    # no latency?
    # http://fomori.org/blog/?p=1213
    #ffmpeg -f x11grab -s $SCREEN_res -framerate 30 -i :0.0 -c:v mpeg2video -q:v 20 -pix_fmt yuv420p -g 1 -threads 2 -f mpegts - | nc -l -p 9000
    ffmpeg -f x11grab -s $SCREEN_res -framerate 30 -i :0.0 -c:v mpeg2video -q:v 20 -pix_fmt yuv420p -g 1 -threads 2 -f mpegts udp://224.0.0.1:9999?pkt_size=131&buffer_size=65535
}


function fn_syncthing_date_repair {
    echo "Running over dir $1"
    #find $1 -type f -name '*~*-*.*'
    #exit

    find $1 -name "*~*-*.*"|while read fname; do
    re="(.+)~([^\.]+)(.+)"
    
        if [[ $fname =~ $re ]]; then
            echo "$fname"
            new_fname=${BASH_REMATCH[1]}${BASH_REMATCH[3]}
            echo $new_fname
            
            # file already exists? 
            if [[ -f $new_fname ]]; then
                $fname_checksum=$(sha1sum "$fname" | awk '{print $1}')
                $new_fname_checksum=$(sha1sum "$new_fname" | awk '{print $1}')
                if [ $fname_checksum == $new_fname_checksum ]; then
                    echo "Removing file as checksum is the same: $fname"
                    rm "$fname"
                fi
            else
                echo "Renaming"
                mv "$fname" "$new_fname"
            fi
            echo ""
        fi
    done
}


function fn_convert_video {
    DIR="${HOME}/Videos/"
    EXT=".mov"
    echo $DIR

    # loop over each one and apply gain
    find "${DIR}" -type f -name "*${EXT}" -print0  | while IFS= read -r -d '' file; do
        #ffmpeg -i "$file" -acodec libmp3lame -q:a 4 -ar 22050 -ac 1 -vcodec libx264 -preset medium -crf 23 -vf "hqdn3d=1.5:1.5:6:6" "${file%.*}.mp4"
        ffmpeg -i "$file" -vcodec h264 -acodec aac -strict -2 "${file%.*}.mp4"
    done
}


function fn_windows_usb {
    loop_dir=/media/loop
    usb_dir=/media/usb

    lsblk
    echo -n "Enter USB Device (ie /dev/sdc): " 
    read device

    # create dirs
    sudo mkdir $usb_dir
    sudo mkdir $loop_dir

    # mount isofile
    iso_file="Win10_Pro_1511_English_x64_july_2016.iso"
    echo "$HOME/Applications/Windows/${iso_file}"
    sudo mount -o loop "$HOME/Applications/Windows/${iso_file}" ${loop_dir}

    # mount
    sudo mount -t vfat ${device}1 $usb_dir

    # copy
    echo "Copying iso files..."
    sudo rsync -ah -r --info=progress2 ${loop_dir}/ ${usb_dir}

    # rejig boot folders
    sudo cp -r $usb_dir/efi/microsoft/boot $usb_dir/efi

    # cleanup
    sudo umount $loop_dir
    sudo umount $usb_dir
    sudo rm -r $usb_dir
    sudo rm -r $loop_dir

    notify-send 'USB' 'Completed'
}



function fn_mp4gain {
    # path for music folder
    DIR=/mnt/a/WorshipClips

    # loop over each one and apply gain
    for file in $DIR/*.mp4
    do
        # read values
        DBLEVEL=`ffmpeg -i "$file" -af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 | grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1`

        # We're only going to increase db level if max volume has negative db level.
        # Bash doesn't do floating comparison directly
        COMPRESULT=`echo ${DBLEVEL}'<'0 | bc -l`

        if [ ${COMPRESULT} -eq 1 ]; then
            
            DBLEVEL=`echo "-(${DBLEVEL})" | bc -l`

            echo "Processing $DBLEVEL $file..."

            ffmpeg -i "${file}" -af "volume=${DBLEVEL}dB" -c:v copy -c:a aac -b:a 96k "${file}.tmp.mp4" -loglevel quiet
            
            mv -f "${file}.tmp.mp4" "${file}"
        fi
        
    done
}


function fn_mp3gain {
    pacaur -S --noconfirm mp3gain

    # path for music folder
    DIR=$HOME/Music


    #find $DIR -type f -iname "*.mp3" -print0 | xargs -0 mp3gain -k -c -s i

    # loop over each one and apply gain
    find $DIR -type f -name '*.mp3' -print0  | while IFS= read -r -d '' file; do
        #printf '%s\n' "$file"
        # -s r = force recalculation, shouldnt need this unless we change the global gain
        # -c = ignore clip warning
        # -k autmatic adjust to avoid clip
        mp3gain -d 10 -k -c -s i "$file"
    done
}


function fn_sound_juicer {
    gvfs-mount cdda://sr0
    sound-juicer
}


function fn_dvd_to_iso {
    # get username
    ID=$(id -nu)
    IDN=$(id -u)
    GIDN=$(id -g)

    # Configuration variables START
    MOUNT_DIR="/run/media/$ID/iso"

    sudo mkdir -p $MOUNT_DIR
    sudo chown $ID:$ID $MOUNT_DIR


    # check if file was supplied
    if [ -z "$1" ]
    then
    echo "ERROR: Please supply file as 1st parameter."
    $SHELL
    fi

    # check if  the mount directory exists
    if [ ! -d "$MOUNT_DIR" ]
    then
    echo "ERROR: Configuration directory MOUNT_DIR=$MOUNT_DIR does not exist."
    $SHELL
    fi

    # collect information
    filename_full="$1"
    filename_nopath=$(basename "$filename_full")
    filename_noext=${filename_nopath%.*}
    filename_path=$(dirname "$filename_full")

    echo $filename_full 
    echo $filename_nopath
    echo $filename_noext
    echo $filename_path

    # check for mounted iso
    sudo umount $MOUNT_DIR

    # mount iso
    echo "Mounting $filename_nopath on $MOUNT_DIR" 
    sudo mount "$filename_full" "$MOUNT_DIR" -t udf -o loop

    # lets encode
    echo "Encoding... $filename_full to $filename_path ..."

    # split into chapters
    n=1

    while [ -e "$MOUNT_DIR/VIDEO_TS/VTS_0"$n"_1.VOB" ]
    do
        echo "Chapter $n"
        cat $MOUNT_DIR/VIDEO_TS/VTS_0"$n"_[123456789].VOB | ffmpeg -i - -movflags faststart -codec:a libmp3lame -q:a 4 -ar 22050 -ac 1 -vcodec libx264 -preset medium -crf 23 -vf "hqdn3d=1.5:1.5:6:6" "$filename_path/$filename_noext-"$n".mp4"
        n=$((n+1))
    done

    #cat $MOUNT_DIR/VIDEO_TS/VTS_0[123456789]_[123456789].VOB | ffmpeg -i - -movflags faststart -codec:a libmp3lame -q:a 4 -ar 22050 -ac 1 -vcodec libx264 -preset medium -crf 23 -vf "hqdn3d=1.5:1.5:6:6" "$filename_path/$filename_noext.mp4"

    # Unmount
    #sudo umount $MOUNT_DIR
}



function fn_dvd_to_video {
    # get username
    ID=$(id -nu)
    IDN=$(id -u)
    GIDN=$(id -g)
    
    # Configuration variables START
    MOUNT_DIR="/run/media/$ID/iso"

    sudo umount "/dev/sr0"
    sudo mkdir -p $MOUNT_DIR
    sudo chown $ID:$ID $MOUNT_DIR

    # collect information
    filename_full="${MOUNT_DIR}"
    filename_nopath=$(basename "$filename_full")
    filename_noext="dvd"
    filename_path=${HOME}

    echo $filename_full
    echo $filename_noext
    echo $filename_path    
    
    # mount dvd
    echo "Mounting $filename_nopath on $MOUNT_DIR" 
    
    sudo mount "/dev/sr0" "$MOUNT_DIR" -t iso9660
    
    # lets encode
    echo "Encoding... $filename_full to $filename_path ..."

    # split into chapters
    n=1
    ls $MOUNT_DIR/video_ts/*_1.vob
    while [ -e "$MOUNT_DIR/video_ts/vts_0"$n"_1.vob" ]
    do
        echo "Chapter $n"
        cat $MOUNT_DIR/video_ts/vts_0"$n"_[123456789].vob | ffmpeg -i - -movflags faststart -codec:a libmp3lame -q:a 4 -ar 22050 -ac 1 -vcodec libx264 -preset medium -crf 23 -vf "hqdn3d=1.5:1.5:6:6" "$filename_path/$filename_noext-"$n".mp4"
        n=$((n+1))
    done
}


function fn_speed_test {
    wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py -q 
    chmod +x speedtest-cli
    python speedtest-cli --server 234
    #--list 
    #--simple
    rm speedtest-cli

    # --server 
    # 234 internode
}

function fn_gpu_preformance {
    # https://wiki.archlinux.org/index.php/ATI#Profile-based_frequency_switching
    # https://github.com/giuliojiang/AMD-Linux-Power-Management

sudo tee /etc/udev/rules.d/30-radeon.rules > /dev/null << EOL    
    KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="radeon", ATTR{device/power_dpm_state}="balanced", ATTR{device/power_dpm_force_performance_level}="low"
EOL


    # cat /sys/class/drm/card0/device/power_dpm_force_performance_level
    # manual, auto, low, high
    echo manual > sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level

    # cat /sys/class/drm/card0/device/power_dpm_state
    # performance, high, low, balanced
    echo low > sudo tee /sys/class/drm/card0/device/power_dpm_state
    echo high > sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level
}

# pass all args
main "$@"
