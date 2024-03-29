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
    r) Reset Network
    n) Network (AP, Bridge, DHCP, DNS)
    s) Samba & pac-cache
    b) Backup service
    m) MPD & DLNA
    a) ai assistant - mycroft
    w) Wireguard VPN
    *) Any key to exit
    :" ans;
    reset
    case $ans in  
        r) fn_reset_network ;;
        n) fn_setup_network ;;
        #2) fn_nm_bridge ;;
        #3) fn_network_info ;;
        #4) fn_wireless_ap ;;
        #5) fn_usb_tether ;;
        #6) fn_bluetooth_tether ;;
        #8) fn_enable_dns_dhcp ;;
        9) fn_disable_dns_dhcp ;;
        #0) fn_nat_gateway ;;

        s) fn_smb ;;
        b) fn_mount_backup ; fn_backup_service ;;
        m) fn_mpd ;;
        #t) fn_update_service ;;
        a) fn_ai_assistant ;;
        w) fn_wireguard ;;
        *) $SHELL ;;
    esac
    done
}


# some handy tools
# ip route or ip r
# ip route get 8.8.8.8

# ip a
# networkctl
# drill
# ping -S 192.168.1.4 on.net
# networkctl status  (add optional number of interface)

# resolvectl status

# links
# http://xmodulo.com/switch-from-networkmanager-to-systemd-networkd.html

function fn_network_info {
    ip r
    networkctl status
}


function fn_wireguard {
    echo "Enter internet address: "
    read endpoint_address

    echo "Enter listen port: "
    read listen_port

    ./util.sh -i wireguard-tools

    # server
    s_private_key=$(wg genkey)
    s_public_key=$(echo $s_private_key | wg pubkey)
    s_preshared_key=$(wg genpsk)

    # client a
    a_private_key=$(wg genkey)
    a_public_key=$(echo $a_private_key | wg pubkey)
    a_preshared_key=$(wg genpsk)

    # client b
    b_private_key=$(wg genkey)
    b_public_key=$(echo $b_private_key | wg pubkey)
    b_preshared_key=$(wg genpsk)

    
    # enabled ip forwarding to allow access to the lan
sudo tee /etc/sysctl.d/30-ipforward.conf > /dev/null << EOL
    net.ipv4.ip_forward=1
    net.ipv6.conf.default.forwarding=1
    net.ipv6.conf.all.forwarding=1
EOL
    sudo sysctl -p /etc/sysctl.d/30-ipforward.conf

    # /etc/wireguard/ for systemd
tee wg-server.conf > /dev/null << EOL
    [Interface]
    Address = 192.168.0.2/24
    ListenPort = ${listen_port}
    PrivateKey = ${s_private_key}
    PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

    [Peer]
    PublicKey = ${a_public_key}
    PresharedKey = ${a_preshared_key}
    AllowedIPs = 192.168.0.3/32

    [Peer]
    PublicKey = ${b_public_key}
    PresharedKey = ${b_preshared_key}
    AllowedIPs = 192.168.0.4/32
EOL

tee wg-client-a.conf > /dev/null << EOL
    [Interface]
    Address = 192.168.0.3/24
    ListenPort = ${listen_port}
    PrivateKey = ${a_private_key}

    [Peer]
    PublicKey = ${s_public_key}
    PresharedKey = ${a_preshared_key}
    AllowedIPs = 192.168.0.0/24
    Endpoint = ${endpoint_address}:${listen_port}
    PersistentKeepalive = 21
EOL

tee wg-client-b.conf > /dev/null << EOL
    [Interface]
    Address = 192.168.0.4/24
    ListenPort = ${listen_port}
    PrivateKey = ${b_private_key}

    [Peer]
    PublicKey = ${s_public_key}
    PresharedKey = ${b_preshared_key}
    AllowedIPs = 192.168.0.0/24
    Endpoint = ${endpoint_address}:${listen_port}
    PersistentKeepalive = 21
EOL
    # use network manager to host the server
    nmcli connection import type wireguard file wg-server.conf

    # prevent network manager management of the server
#sudo tee /etc/NetworkManager/conf.d/unmanaged.conf > /dev/null << EOL
#    [keyfile]
#    unmanaged-devices=interface-name:wg*
#EOL

    # start systemd service
    #sudo systemctl enable wg-quick@wg-server
    #sudo systemctl restart wg-quick@wg-server
    #sudo wg show

    qrencode -t ansiutf8 < wg-client-a.conf
}


function fn_ai_assistant {
    # https://mycroft-ai.gitbook.io/docs/using-mycroft-ai/get-mycroft/linux

    cd ~/
    git clone https://github.com/MycroftAI/mycroft-core.git
    cd mycroft-core
    ./dev_setup.sh

    ./start-mycroft.sh all

    # broken on aur 2022
    #./util.sh -i mycroft-core mycroft-gui-git

    #VAR1='#load-module module-native-protocol-tcp'
    #VAR2='load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1'
    #sudo sed -i -e "s/${VAR1}/${VAR2}/g" /etc/pulse/default.pa
    #pulseaudio -k
    #sudo systemctl start mycroft.service
}


function fn_setup_network {
    #fn_enable_dns_dhcp
    fn_nm_bridge
}


function fn_reset_network {
    # any files you create, add here for deletion
    # any services, add them here too!

    files=(
        /etc/systemd/network/mobile.network
        /etc/systemd/network/bluetooth.network
        /etc/systemd/network/bridge.netdev
        /etc/systemd/network/bridge.network
        /etc/systemd/network/ethernet.network
        /etc/hostapd/hostapd.conf
        /usr/lib/systemd/system/hostapd.service
        /etc/resolv.conf
        /etc/dnsmasq.conf
        /etc/hosts
    )
    
    # loop
    for file in ${files[*]} ; do
        sudo rm ${file}
    done

sudo tee /etc/hosts > /dev/null << EOL
    127.0.0.1       localhost
EOL

    # delete nft
    sudo nft flush ruleset  

    # flush routes
    sudo ip route flush table main
    #sudo ip route flush cache

    # resore resolve files
sudo tee /etc/resolv.conf > /dev/null << EOL
# Generated by NetworkManager
nameserver 192.168.1.1
EOL

sudo tee /etc/resolvconf.conf > /dev/null << EOL
# Configuration for resolvconf(8)
# See resolvconf.conf(5) for details

resolv_conf=/etc/resolv.conf
# If you run a local name server, you should uncomment the below line and
# configure your subscribers configuration files below.
#name_servers=127.0.0.1
EOL

    # restore services
    sudo rm -rf /etc/NetworkManager/*
    fn_enable_network_manager

    # TODO: systemd routes??

    notify-send 'Network' 'Defaults restored'
}


function fn_usb_tether {
    # https://wiki.archlinux.org/index.php/Android_tethering
    # get idVendor
    vendor_id=2717
    device_name=enp0s20u1
    udevadm info /sys/class/net/${device_name} | awk '/ID_VENDOR_ID/{print $2}'
    
    
sudo tee /etc/udev/rules.d/90-mobile.rules > /dev/null << EOL
    # Execute pairing program when appropriate
    ACTION=="add|remove", SUBSYSTEM=="net", ATTR{idVendor}=="${vendor_id}" ENV{ID_USB_DRIVER}=="rndis_host", SYMLINK+="android", RUN+="/usr/bin/systemctl restart systemd-networkd.service"
EOL

sudo tee /etc/systemd/network/mobile.network > /dev/null << EOL
    [Match]
    Name=enp0s2*

    [Network]
    Address=192.168.1.4/24
    DNS=192.168.1.4
    Gateway=192.168.1.4
    IPForward=yes
EOL

    fn_enable_systemd_network

    inet=enp0s20u1

    # create chains
    sudo nft add table ip nat
    sudo nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }
    sudo nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }
    # add rule
    sudo nft add rule nat postrouting oifname ${inet} masquerade    
}

function fn_enable_systemd_network {
    sudo systemctl daemon-reload

    # stop network manager
    sudo systemctl stop NetworkManager
    sudo systemctl mask NetworkManager

    # enable systemd
    sudo systemctl unmask systemd-networkd
    sudo systemctl enable systemd-networkd
    sudo systemctl restart systemd-networkd

    sudo systemctl unmask systemd-resolved
    sudo systemctl enable systemd-resolved
    sudo systemctl restart systemd-resolved

    # disable dhcp client for static ip
    sudo systemctl mask dhcpcd

    sudo rm /etc/resolv.conf
    sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
}


function fn_enable_network_manager {
    sudo systemctl daemon-reload

    sudo systemctl stop systemd-networkd
    sudo systemctl disable systemd-networkd

    sudo systemctl stop systemd-resolved
    sudo systemctl disable systemd-resolved
    sudo unlink /etc/resolv.conf

    sudo systemctl unmask NetworkManager
    sudo systemctl restart NetworkManager
}


function fn_bluetooth_tether {
    # https://wiki.archlinux.org/index.php/Internet_sharing
    # https://wiki.archlinux.org/index.php/Bluetooth#Installation
    # https://wiki.archlinux.org/index.php/Android_tethering#Tethering_via_Bluetooth 
    yay --noconfirm --needed -S nftables
    yay --noconfirm --needed -S bluez bluez-utils

    bluetoothctl devices
    # awk, find line 'Device' and get 2nd entry on line
    # sed replace : with _
    device_mac=$(bluetoothctl info | awk '/^Device/{print $2}' | sed 's/:/_/g')
    dbus-send --system --type=method_call --dest=org.bluez /org/bluez/hci0/dev_${device_mac} org.bluez.Network1.Connect string:'nap'
    
    # bnep0
    #if false; then
sudo tee /etc/systemd/network/bluetooth.network > /dev/null << EOL
    [Match]
    Name=bn*

    [Network]
    Address=192.168.2.5/24
    Gateway=192.168.2.5
    DNS=192.168.2.5
    IPForward=yes
EOL
    #fi

    fn_enable_systemd_network
    networkctl status

    sudo sysctl net.ipv4.ip_forward=1
    # sudo sysctl -a | grep forward

    # NAT
    # br0 (bridge) -> bnap0 (bluetooth)

    inet=bnap0

    sudo nft flush ruleset 

    # create chains
    sudo nft add table ip nat
    sudo nft add chain ip nat prerouting { type nat hook prerouting priority 0 \; }
    sudo nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }
    # add rule
    sudo nft add rule nat postrouting oifname ${inet} masquerade

    # optional simple firewall
    #sudo nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop}
    #sudo nft add rule filter forward ct state related,established accept
    #sudo nft add rule filter forward iifname net0 oifname ${inet} accept

    sudo nft list ruleset
}


function fn_nm_bridge {
    # network manager version of network bridge
    # reset to defaults
    echo "Enter AP password: "
    read ap_password

    sudo rm -rf /etc/NetworkManager/*
    sudo systemctl restart NetworkManager


    # create bridge
    bridge_device='br0'
    bridge_name='Network-Bridge'
    sudo nmcli connection add type bridge ifname ${bridge_device} con-name ${bridge_name} bridge.stp no

    # static ip
    sudo nmcli connection modify ${bridge_name} ipv4.addresses '192.168.1.2/24'
    sudo nmcli connection modify ${bridge_name} ipv4.gateway '192.168.1.1'
    sudo nmcli connection modify ${bridge_name} ipv4.dns '192.168.1.1'
    sudo nmcli connection modify ${bridge_name} ipv4.dns-search ''
    sudo nmcli connection modify ${bridge_name} ipv4.method manual


    # add etheernet devices into bridge
    nmcli device status | grep -o "^enp\w*" | while read -r line ; do
        sudo nmcli connection add type bridge-slave ifname ${line} master ${bridge_device}
    done
    
    
    # host wifi ap
    wifi_device=$(nmcli device status | grep -o "^wlp\w*")
    ssid='spud'
    wifi_name='Wireless-Access-Point'

    nmcli c add type wifi ifname ${wifi_device} con-name ${wifi_name} autoconnect yes ssid ${ssid}
    nmcli connection modify ${wifi_name} 802-11-wireless.mode ap 802-11-wireless.band bg
    nmcli connection modify ${wifi_name} wifi-sec.key-mgmt wpa-psk
    nmcli connection modify ${wifi_name} wifi-sec.psk ${ap_password}
    nmcli connection modify ${wifi_name} ipv4.addresses '192.168.0.2/24'
    nmcli connection modify ${wifi_name} ipv4.gateway '192.168.0.2'
    nmcli connection modify ${wifi_name} ipv4.method shared 
    nmcli connection up ${wifi_name}

    # cannot bridge the network using metho shared
    #sudo nmcli connection add type bridge-slave ifname ${wifi_device} master ${bridge_device}

    # turn on bridge
    sudo nmcli con up ${bridge_name}

    # status
    nmcli device status
    nmcli general hostname
    nmcli con show ${bridge_name} | grep -E 'ipv4.dns|ipv4.addresses|ipv4.gateway'

    notify-send 'Network' 'Static ip configured'
}


function fn_systemd_bridge {
    # systemd version of network bridge
    # https://wiki.archlinux.org/index.php/Systemd-networkd
    
    # bridge virtual device
sudo tee /etc/systemd/network/bridge.netdev > /dev/null << EOL
    [NetDev]
    Name=br0
    Kind=bridge
EOL
# 
    # setup bridge network
sudo tee /etc/systemd/network/bridge.network > /dev/null << EOL
    [Match]
    Name=br0

    [Network]
    #DHCP=ipv4
    Address=192.168.1.2/24
    DNS=192.168.1.1
    Gateway=192.168.1.1
    IPForward=yes
EOL

    # setup ethernet
    # add devices to bridge
sudo tee /etc/systemd/network/ethernet.network > /dev/null << EOL
    [Match]
    Name=en*

    [Network]
    Bridge=br0
    #DHCP=ipv4
EOL

    # services
    fn_enable_systemd_network
    networkctl status

    notify-send 'Network' 'Static ip configured'
}

function fn_wireless_ap {
    HEADERS=$(echo "linux$(uname -r | awk -F "." '{print $1$2}')-headers")
    #yay --noconfirm -S ${HEADERS}
    
    yay --noconfirm --needed -S hostapd
    
    # ap mode supported?
    iw list | grep AP$
    
    WLAN=$(iw dev | awk '$1=="Interface"{print $2}')
    
    echo "Enter AP password: "
    read ap_password
    
    # hostapd, no tabs supported!
sudo tee /etc/hostapd/hostapd.conf > /dev/null << EOL
interface=${WLAN}
bridge=br0

# Driver interface type (hostap/wired/none/nl80211/bsd)
driver=nl80211

# SSID to be used in IEEE 802.11 management frames
ssid=spud
country_code=AU
hw_mode=g
channel=7

# n mode settings
wme_enabled=1
ieee80211n=1
#[SHORT-GI-40][DSSS_CCK-40] #40mhz not suported, goto ebay!
ht_capab=[HT40+]

# paraphrase/encryption
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$ap_password
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

# overwrite hostapd service file
sudo tee /usr/lib/systemd/system/hostapd.service > /dev/null << EOL
    [Unit]
    Description=Hostapd IEEE 802.11 AP, IEEE 802.1X/WPA/WPA2/EAP/RADIUS Authenticator
    After=network.target

    [Service]
    ExecStart=/usr/bin/hostapd /etc/hostapd/hostapd.conf
    ExecReload=/bin/kill -HUP $MAINPID
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
EOL

    fn_enable_systemd_network
    sudo systemctl daemon-reload
    sudo systemctl enable hostapd
    sudo systemctl restart hostapd
}



function fn_disable_dns_dhcp {

sudo tee /etc/resolv.conf > /dev/null << EOL
    nameserver 192.168.1.1
EOL


sudo tee /etc/dnsmasq.conf > /dev/null << EOL
EOL


sudo tee /etc/hosts > /dev/null << EOL
    127.0.0.1       localhost
    192.168.1.2     s
    192.168.1.1     router
EOL


    # dhcp/dns enabled
    sudo systemctl stop dnsmasq
    sudo systemctl disable dnsmasq

    fn_enable_systemd_network   
}


function fn_enable_dns_dhcp {
    # https://www.linux.com/learn/dnsmasq-easy-lan-name-services
    # https://www.linux.com/learn/intro-to-linux/2018/2/dns-and-dhcp-dnsmasq
    
    sudo pacman --noconfirm --needed -S dnsmasq
    
    # adblock
    # https://www.middling.uk/blog/2015/09/ad-blocking-using-dns-and-privoxy-with-squid-for-caching/
    sudo wget -O /etc/dnsmasq.conf.ads-yoyo "http://pgl.yoyo.org/as/serverlist.php?hostformat=dnsmasq-server&showintro=0&startdate%5Bday%5D=&startdate%5Bmonth%5D=&startdate%5Byear%5D=&mimetype=plaintext"    
    
sudo tee /etc/resolv.conf > /dev/null << EOL
    resolvconf=NO
EOL


sudo tee /etc/dnsmasq.conf > /dev/null << EOL
    domain-needed
    bogus-priv
    no-resolv # may fail dns blocking?
    no-poll # may fail dns blocking?
    #strict-order

    # local domain name 
    # ie pcname.lan
    domain=lan
    expand-hosts
    local=/lan/ 
    
    # dhcp
    dhcp-range=192.168.1.100,192.168.1.200, 48h
    #dhcp-range=wifi,192.168.2.100,192.168.2.200, 48h
    
    # subnet mask
    dhcp-option=1,255.255.255.0
    
    # gateway
    dhcp-option=3,192.168.1.1

    # DNS server
    dhcp-option=6,192.168.1.2
    
    # other options
    # options listed using dnsmasq --help dhcp
    #dhcp-lease-max=25 
    #dhcp-option=eth,option:ntp-server,192.168.10.5
    
    # upstream name servers
    server=208.67.222.222
    server=208.67.220.220
    #server=8.8.8.8
    #server=8.8.4.4    
    
    # TFTP server
    #dhcp-boot=pxelinux.0
    
    # DNS adblock
    conf-file=/etc/dnsmasq.conf.ads-yoyo
    
    # static address in dhcp range
    #dhcp-host=d0:50:99:82:e7:2b,192.168.10.46 # by mac
    #dhcp-host=hostname,192.168.10.45 # by hostname
EOL


sudo tee /etc/hosts > /dev/null << EOL
    127.0.0.1       localhost
    192.168.1.2     s
    192.168.1.1     router
EOL

    # dhcp/dns enabled
    sudo systemctl enable dnsmasq
    sudo systemctl restart dnsmasq
}


function fn_nat_gateway {
    # we should not need this
    # this is only for testing purposes
    
    # using nftables
    yay --noconfirm --needed -S nftables
    
    #h ttps://linoxide.com/firewall/configure-nftables-serve-internet/
    # https://wiki.nftables.org/wiki-nftables/index.php/Load_balancing
    # https://wiki.nftables.org/wiki-nftables/index.php/Performing_Network_Address_Translation_(NAT)
    # https://home.regit.org/netfilter-en/nftables-quick-howto/
    # https://kernelnewbies.org/nftables_examples#NAT
 
    # delete all
    sudo nft flush ruleset   
    
    # FILTER table
    sudo nft add table FILTER
    sudo nft add chain FILTER input { type filter hook input priority 0 \; }
    sudo nft add chain FILTER forward { type filter hook forward priority 0 \; }
    sudo nft add chain FILTER output { type filter hook output priority 0 \; }

    # allow all for testing
    sudo nft add rule FILTER output accept
    
    
    # FILTER table (input from lan only version of above)
    sudo nft flush ruleset 
    sudo nft add table FILTER
    sudo nft add chain FILTER input { type filter hook input priority 0 \; }
    sudo nft add rule ip FILTER input ip daddr 192.168.0.0/24
    
    
    # drop all packets to this machine
    #sudo nft add rule FILTER input ct state new drop
    # packets realted to or established
    #sudo nft add rule FILTER input ct state related,established accept
    
    # allow these packets to this machine
    # ssh
    # sudo nft insert rule filter input tcp port 22 accept
    # dns
    #sudo nft insert rule FILTER input tcp port 53 accept
    #sudo nft insert rule FILTER input udp port 53 accept

    # kde connect
    #sudo nft insert rule FILTER input tcp port {1714-1764} accept
    #sudo nft insert rule FILTER input udp port {1714-1764} accept
    
    # ROUTE table
    #sudo nft add table MANGLE
    #sudo nft 'add chain MANGLE output { type route hook output priority -150; }' # because of the negative
    
    

    # NAT
    # changes our lan ip to inet packet by modifying the source address to the inet address
    
    # Source NAT - changes source address/port in packet
    #   - When packet is sent from NAT, the source(return) address is change to the NET/NAT address
    
    # Destination NAT - changes destination address/port in packet
    #   - When the packet is returned to the NAT, the destination is changed to the LAN address
    
    # Masquerade - like Source NAT but inet ip is dynamic/unknown(DHCP)
    
    # NAT loopback ...
    
    # NAT table
    sudo nft flush ruleset 
    sudo nft add table NAT
    sudo nft add chain NAT prerouting { type nat hook prerouting priority 0 \; }
    sudo nft add chain NAT postrouting { type nat hook postrouting priority 100 \; }    
    
    # anything from LAN -> net
    #sudo nft add rule NAT postrouting ip saddr 192.168.1.0/24 oif br0 snat 192.168.1.2
    sudo nft add rule NAT postrouting ip saddr 192.168.1.0/24 masquerade
    
    # load balancing version of above 
    # numgen inc mod 2 map = math generating a random number
    #sudo nft add rule NAT prerouting dnat to numgen inc mod 2 map { 0 : 192.168.1.1, 1 : 192.168.1.1 }
                         
    # dns
    #sudo nft add rule NAT prerouting udp dport 53 ip saddr 192.168.1.0/24 dnat 8.8.8.8:53

    # tcp port 80 & 443 to 192.168.1.120
    #sudo nft add rule NAT prerouting iif eth0 tcp dport { 80, 443 } dnat 192.168.1.120

    # list NAT
    sudo nft list table NAT -a
    
    # list tables
    sudo nft list tables

    # save the rule to make permanent
    sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
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
    TimeoutIdleSec=1800

    [Install]
    WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable mnt-backup.automount
    sudo systemctl restart mnt-backup.automount

}

function fn_backup_service {
    sudo pacman --noconfirm -S borg python-llfuse

    # daily backup
sudo tee /etc/systemd/system/tool-backup.service > /dev/null << EOL
    [Unit]
    Description=Backup Service

    [Service]
    ExecStart=/home/s/Projects/scripts/tools.sh fn_backup_borg
EOL

sudo tee /etc/systemd/system/tool-backup.timer > /dev/null << EOL 
    [Unit]
    Description=Daily backup

    [Timer]
    OnCalendar=daily
    Persistent=true   
    Unit=tool-backup.service

    [Install]
    WantedBy=timers.target
EOL

    # Start timer, as root
    sudo systemctl restart tool-backup.timer

    # Enable timer to start at boot
    sudo systemctl enable tool-backup.timer

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
        
        # printer
        printing = CUPS
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

    [printers]
        comment = All Printers
        path = /var/spool/samba
        browseable = yes
        guest ok = yes
        printable = yes
        create mask = 0600

    # read + write
    [Downloads]
        comment = Public
        path = /home/s/Downloads
        writeable = yes

    # read only
    [Emulators]
        comment = Public
        path = /home/s/Emulators
        read only = yes
        writeable = no	

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



function fn_mpd {
    ID_NAME=$(id -nu)

    ./util.sh -i alsa-utils ffmpeg mpd upmpdcli 
    # ncmpcpp 

    # setup library links
    mkdir $HOME/.config/mpd
    #ln -s $HOME/Bible ${HOME}/Music/Bible
    
    # mpd config
tee $HOME/.config/mpd/mpd.conf > /dev/null << EOL       
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
    #sudo sed -i -e "s/User=mpd/User=${ID_NAME}\nPAMName=system-local-login/g" /usr/lib/systemd/system/mpd.service

    # new method
sudo tee /usr/lib/systemd/system/mpd.service.d/00-arch.conf > /dev/null << EOL       
    [Service]
    User=s
    PAMName=system-local-login
EOL
    
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
