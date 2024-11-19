#!/bin/bash

# https://peppe8o.com/raspberry-pi-portable-hotspot-with-android-usb-tethering/

## ==== MAIN CODE ====

sudo apt install nftables
sudo systemctl enable nftables
sudo systemctl restart nftables


# enable forwarding/routing - done in the network files
#sudo nano /etc/sysctl.conf
#net.ipv4.ip_forward=1
#sudo sysctl -p


# disable systemd resolv (dns server)
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf > /dev/null << EOL
[Resolve]
DNSStubListener=no
EOL
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved


# link file
# this renames the device to a better name
sudo tee /etc/systemd/network/10-internet-usb.link > /dev/null << EOL
[Match] 
Path=*-usb-*
Property=ID_NET_NAME_MAC=*

[Link] 
Name=usb0
EOL

# setup network
# networkctl status
# networkctl status usb0
sudo tee /etc/systemd/network/10-internet-usb.network > /dev/null << EOL
[Match]
Name=usb*

[Network]
DHCP=yes
LinkLocalAddressing=ipv6
IPv6PrivacyExtensions=yes

IPv4Forwarding=yes
IPv6Forwarding=yes
IPMasquerade=both

[DHCPv4] 
# lower route metric is higher priority
RouteMetric=100
UseMTU=true
EOL

sudo tee /etc/systemd/network/10-lan.network > /dev/null << EOL
[Match]
Name=end0

[Network]
Address=192.168.1.6/24
#Gateway=192.168.1.1
#DNS=192.168.1.3

#IPv4Forwarding=yes
#IPv6Forwarding=yes
#IPMasquerade=both
EOL


sudo systemctl daemon-reload
sudo systemctl enable systemd-networkd
sudo systemctl restart systemd-networkd

# need system reboot here


# nftables routing
sudo mkdir /etc/nftables.d
sudo tee /etc/nftables.d/nat.conf > /dev/null << EOL
table ip nat {
        chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                oif "usb0" masquerade
        }
}
EOL

echo 'include "/etc/nftables.d/*.conf"' | sudo tee -a /etc/nftables.conf
