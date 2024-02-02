#!/bin/bash

# network manager version of network bridge



phone_wifi_device='wlp0s20u2' # which devices for connecting to phone hotspot?
lan_wifi_device='wlp4s0' # which device for LAN devices?

ssid='spud_test' # Enter what you want to call your wifi

# reset to defaults
echo '[Router] Resetting network manager defaults'
sudo rm -rf /etc/NetworkManager/*
sudo systemctl restart NetworkManager

#exit # enable this line to reset the networking to linux default

echo "Enter password you want for your wifi '${ssid}' (min length 8): "
read ap_password
#ap_password='1234567890' # TODO: temporary to save us typing it in all the time


# set up the phone wifi to connect to any avilable hotposts
#sudo nmcli dev wifi connect network-ssid password "network-password"
phone1_wifi_name='MelissaM'
phone1_wifi_password='1234567890' # TODO: make this an input
phone2_wifi_name='FabianM'
phone2_wifi_password='1234567890' # TODO: make this an input

echo '[Router] Trying to connect to phone hotspots'
sleep 10s # need time for network mgr to get up and detect wifi networks
#nmcli connection up ${phone1_wifi_name} ifname ${phone_wifi_device}
nmcli dev wifi connect ${phone2_wifi_name} password ${phone2_wifi_password} ifname ${phone_wifi_device}
nmcli dev wifi connect ${phone1_wifi_name} password ${phone1_wifi_password} ifname ${phone_wifi_device}

#nmcli connection up ${phone1_wifi_name} ifname ${phone_wifi_device}


# create bridge
bridge_device='br0'
bridge_name='Network-Bridge'
echo '[Router] Setting up bridge'
nmcli connection add type bridge ifname ${bridge_device} con-name ${bridge_name} bridge.stp no

# static ip
#sudo nmcli connection modify ${bridge_name} ipv4.addresses '192.168.1.2/24'
#sudo nmcli connection modify ${bridge_name} ipv4.gateway '192.168.1.1'
#sudo nmcli connection modify ${bridge_name} ipv4.dns '192.168.1.1'
#sudo nmcli connection modify ${bridge_name} ipv4.dns-search ''
#sudo nmcli connection modify ${bridge_name} ipv4.method manual


# add ethernet devices into bridge
nmcli device status | grep -o "^en\w*" | while read -r line ; do
    echo "[Router] Adding ethernet device '${line}'"
    nmcli connection add type bridge-slave ifname ${line} master ${bridge_device}
done


# add ethernet devices into bridge
nmcli connection add type bridge-slave ifname ${phone_wifi_device} master ${bridge_device}
nmcli connection add type bridge-slave ifname ${lan_wifi_device} master ${bridge_device}


# host wifi ap
wifi_device=${lan_wifi_device} #$(nmcli device status | grep -o "^wlp\w*")

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
echo '[Router] Network status:'
nmcli device status
nmcli general hostname
nmcli con show ${bridge_name} | grep -E 'ipv4.dns|ipv4.addresses|ipv4.gateway'

echo '[Router] Router configured'
notify-send 'Network' 'Router configured'