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
    1) Restore defaults
    2) Network bridge
    3) DHCP & DNS
    4) Wifi AP
    5) USB Tether
    6) Bluetooth Tether
    0) NAT Gateway
    *) Any key to exit
    :" ans;
    reset
    case $ans in
        1) fn_restore_network ;;
        2) fn_network_bridge ;;
        3) fn_dns_dhcp ;;
        4) fn_wireless_ap ;;
        5) fn_usb_tether ;;
        6) fn_bluetooth_tether ;;
        0) fn_nat_gateway ;;
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

function fn_restore_network {
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

    # restore services
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

    sudo systemctl stop NetworkManager
    sudo systemctl mask NetworkManager

    sudo systemctl unmask systemd-networkd
    sudo systemctl enable systemd-networkd
    sudo systemctl restart systemd-networkd

    sudo systemctl unmask systemd-resolved
    sudo systemctl enable systemd-resolved
    sudo systemctl restart systemd-resolved
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


function fn_network_bridge {
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
    DNS=192.168.1.2
    Gateway=192.168.1.3
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



function fn_dns_dhcp {
    # https://www.linux.com/learn/dnsmasq-easy-lan-name-services
    # https://www.linux.com/learn/intro-to-linux/2018/2/dns-and-dhcp-dnsmasq
    
    sudo pacman --noconfirm -S dnsmasq
    
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
    dhcp-option=3,192.168.1.3

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
    192.168.1.3     router
EOL


    sudo systemctl enable dnsmasq
    sudo systemctl restart dnsmasq

    systemctl mask dhcpcd

    fn_enable_systemd_network   
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
    #sudo nft add rule NAT prerouting dnat to numgen inc mod 2 map { 0 : 192.168.1.3, 1 : 192.168.1.3 }
                         
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


# pass all args
main "$@"
