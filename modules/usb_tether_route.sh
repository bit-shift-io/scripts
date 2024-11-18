#!/bin/bash

# https://peppe8o.com/raspberry-pi-portable-hotspot-with-android-usb-tethering/

## ==== MAIN CODE ====

sudo apt install nftables
sudo systemctl enable nftables
sudo systemctl restart nftables


# enable forwarding/routing
sudo nano /etc/sysctl.conf
net.ipv4.ip_forward=1
sudo sysctl -p


# disable systemd resolv (dns server)
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf > /dev/null << EOL
[Resolve]
DNSStubListener=no
EOL
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved


# routing rules
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


# setup network

sudo tee /etc/systemd/network/20-usb-tether.network > /dev/null << EOL
[Match]
# Use    udevadm info  /sys/class/net/INTERFACE_NAME   to list the udev properties and pick one or more
#Property=ID_MODEL=SAMSUNG_Android "ID_USB_DRIVER=rndis_host"
Name=eth0

[Network]
DHCP=ipv4

[DHCPv4] 
# Default metric is 1024, setting a value lower makes this the default route
RouteMetric=512
EOL


sudo tee /etc/systemd/network/10-lan.network > /dev/null << EOL
[Match]
Name=end0

[Network]
Address=192.168.1.6/24
#DHCPServer=yes

#[DHCPServer]
#PoolOffset=10
#PoolSize=10
#LeaseTime=12h

# MAC address based IP assignment example
#Host=9e:da:db:7a:1e:ab
#IPAddress=192.168.1.6
#HostName=iot

# DNS Servers
#DNS=8.8.8.8
#DNS=8.8.4.4
EOL


sudo systemctl enable systemd-networkd
sudo systemctl restart systemd-networkd


# note: we can use udev to setup rules to enable and disable routing when the usb device is connected
# however as we are the source of internet, it shouldnt really matter to just leave the routing rules 
# running all the time...

# note: if we are running adguard, then we shouldnt need the dhcp stuff in the lan network
