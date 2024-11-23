#!/bin/bash

# https://peppe8o.com/raspberry-pi-portable-hotspot-with-android-usb-tethering/
# https://oxcrag.net/projects/linux-router-part-1-routing-nat-and-nftables/
# https://wiki.nftables.org/wiki-nftables/index.php/Simple_ruleset_for_a_home_router

## ==== MAIN CODE ====


sudo apt install nftables
sudo systemctl enable nftables
sudo systemctl restart nftables

sudo apt remove netplan.io
sudo apt autoremove


# enable forwarding/routing - done in the network files
#sudo nano /etc/sysctl.conf
#net.ipv4.ip_forward=1
#sysctl net.ipv4.conf.all.rp_filter=0
#sudo sysctl -p
# cat /proc/sys/net/ipv4/ip_forward


# disable systemd resolv (dns server)
# should we set resolve to use 127.0.0.1?
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

#IPv4Forwarding=yes
#IPv6Forwarding=yes
#IPMasquerade=both

[DHCPv4] 
# lower route metric is higher priority 1024 default? or 100?
#RouteMetric=100
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

#[Route]
#Gateway=192.168.1.6
#Destination=0.0.0.0/0
#GatewayOnLink=yes
EOL


sudo systemctl daemon-reload
sudo systemctl enable systemd-networkd
sudo systemctl restart systemd-networkd

# need system reboot here

#
sudo nft add table ip nat
sudo nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }
sudo nft add rule ip nat postrouting oif "usb0" masquerade

# nftables routing
sudo mkdir /etc/nftables.d
sudo tee /etc/nftables.d/nat.conf > /dev/null << EOL
flush ruleset

# Filter Table (for packet filtering)
table inet filter {
    chain input {
        type filter hook input priority 0; policy accept;
    }

    chain forward {
        type filter hook forward priority filter; policy accept;
        # Allow forwarding between end0 and usb0
        iif "end0" oif "usb0" accept
        iif "usb0" oif "end0" accept
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}

# NAT Table (for Network Address Translation)
table ip nat {
    chain prerouting {
        type nat hook prerouting priority filter; policy accept;
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oif "usb0" masquerade  # Masquerading for traffic from end0
    }
}
EOL

# add include to the bottom of nftables.conf
echo 'include "/etc/nftables.d/*.conf"' | sudo tee -a /etc/nftables.conf
sudo nft -f /etc/nftables.conf
sudo nft -f /etc/nftables.d/nat.conf
sudo nft list ruleset

sudo journalctl | grep "ICMP Echo Reply"

#default via 192.168.1.6 dev end0 
#172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
#172.18.0.0/16 dev br-cc00a7d88795 proto kernel scope link src 172.18.0.1 
#192.168.1.0/24 dev end0 proto kernel scope link src 192.168.1.6 
#192.168.102.0/24 dev usb0 proto kernel scope link src 192.168.102.114 metric 1024 
#192.168.102.208 dev usb0 proto dhcp scope link src 192.168.102.114 metric 1024 

sudo tee /etc/nftables.d/net.conf > /dev/null << EOL
#!/usr/sbin/nft -f

# Clear out any existing rules
flush ruleset

# Our future selves will thank us for noting what cable goes where and labeling the relevant network interfaces if it isn't already done out-of-the-box.
define WANLINK = usb0
define LANLINK = end0

# I will be presenting the following services to the Internet. You perhaps won't, in which case the following line should be commented out with a # sign similar to this line.
define PORTFORWARDS = { http, https }

# We never expect to see the following address ranges on the Internet
define BOGONS4 = { 0.0.0.0/8, 10.0.0.0/8, 10.64.0.0/10, 127.0.0.0/8, 127.0.53.53, 169.254.0.0/16, 172.16.0.0/12, 192.0.0.0/24, 192.0.2.0/24, 192.168.0.0/16, 198.18.0.0/15, 198.51.100.0/24, 203.0.113.0/24, 224.0.0.0/4, 240.0.0.0/4, 255.255.255.255/32 }

# The actual firewall starts here
table inet filter {
    # Additional rules for traffic from the Internet
	chain inbound_world {
                # Drop obviously spoofed inbound traffic
                ip saddr { $BOGONS4 } drop
	}
    # Additional rules for traffic from our private network
	chain inbound_private {
                # We want to allow remote access over ssh, incoming DNS traffic, and incoming DHCP traffic
		ip protocol . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 67 : accept }
	}
        # Our funnel for inbound traffic from any network
	chain inbound {
                # Default Deny
                type filter hook input priority 0; policy drop;
                # Allow established and related connections: Allows Internet servers to respond to requests from our Internal network
                ct state vmap { established : accept, related : accept, invalid : drop} counter

                # ICMP is - mostly - our friend. Limit incoming pings somewhat but allow necessary information.
		icmp type echo-request counter limit rate 5/second accept
		ip protocol icmp icmp type { destination-unreachable, echo-reply, echo-request, source-quench, time-exceeded } accept
                # Drop obviously spoofed loopback traffic
		iifname "lo" ip daddr != 127.0.0.0/8 drop

                # Separate rules for traffic from Internet and from the internal network
                iifname vmap { lo: accept, $WANLINK : jump inbound_world, $LANLINK : jump inbound_private }
	}
        # Rules for sending traffic from one network interface to another
	chain forward {
                # Default deny, again
		type filter hook forward priority 0; policy drop;
                # Accept established and related traffic
		ct state vmap { established : accept, related : accept, invalid : drop }
                
                # Let traffic from this router and from the Internal network get out onto the Internet
		##iifname { lo, $LANLINK } accept
                # Only allow specific inbound traffic from the Internet (only relevant if we present services to the Internet).
		##tcp dport { $PORTFORWARDS } counter

                # Allow traffic between the two interfaces
                iifname $WANLINK oifname $LANLINK accept
                iifname $LANLINK oifname $WANLINK accept
	}
}

# Network address translation: What allows us to glue together a private network with the Internet even though we only have one routable address, as per IPv4 limitations
table ip nat {
        chain  prerouting {
		type nat hook prerouting priority -100;
                # Send specific inbound traffic to our internal web server (only relevant if we present services to the Internet).
		iifname $WANLINK tcp dport { $PORTFORWARDS } dnat to 192.168.1.6
        }
	chain postrouting {
		type nat hook postrouting priority 100; policy accept;
                # Pretend that outbound traffic originates in this router so that Internet servers know where to send responses
		oif $WANLINK masquerade
	}
}
EOL







sudo tee
#!/usr/sbin/nft -f

flush ruleset

table inet firewall {
    chain input {
        type filter hook input priority 0; policy drop;

        # allow localhost
        iif "lo" accept

        # allow from wan interface
        iifname "enp1s0" accept

        # allow return traffic
        ct state established,related accept

        # allow ICMP
        meta l4proto { icmp, ipv6-icmp } accept

        # allow DHCP from LAN
        iifname { "end0" } udp dport 67 accept

        # allow DNS from LAN and live
        iifname { "end0" } tcp dport 53 accept
        iifname { "end0" } udp dport 53 accept

        # allow NTP
        iifname { "end0" } udp dport 123 accept

        reject with icmpx type admin-prohibited
    }

    chain forward-internet-to-lan {
        # allow ICMP
        meta l4proto { icmp, ipv6-icmp } accept

        # allow return traffic
        ct state established,related accept

        reject with icmpx type admin-prohibited
    }

    chain forward-internet-to-live {
        # allow ICMP
        meta l4proto { icmp, ipv6-icmp } accept

        # allow all traffic
        accept
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # allow ICMP
        meta l4proto { icmp, ipv6-icmp } accept

        iifname "usb0" oifname "end0" jump forward-internet-to-lan
        #iifname "usb0" oifname "enp3s0" jump forward-internet-to-live

        # allow from lan to internet, live
        iifname "end0" oifname { "usb0" } accept

        # allow return traffic
        ct state established,related accept

        reject with icmpx type admin-prohibited
    }
}

table ip nat {
    chain postrouting {
        type nat hook postrouting priority 0;

        ip saddr 192.168.0.0/16 oifname "usb0" masquerade fully-random
    }
}

EOL
