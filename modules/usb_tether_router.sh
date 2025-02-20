#!/bin/bash


# disable systemd resolv (dns server)
# should we set resolve to use 127.0.0.1?
echo "disable systemd-resolved..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/disable-stub.conf > /dev/null << EOL
[Resolve]
DNSStubListener=no
EOL
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
#sudo systemctl restart systemd-resolved
sudo systemctl enable systemd-resolved --now


echo "set internet name to usb0..."
sudo tee /etc/systemd/network/10-internet-usb.link > /dev/null << EOL
[Match] 
Path=*-usb-*
Property=ID_NET_NAME_MAC=*

[Link] 
Name=usb0
EOL


echo "config usb internet..."
sudo tee /etc/systemd/network/10-internet-usb.network > /dev/null << EOL
[Match]
Name=usb*

[Network]
DHCP=yes
LinkLocalAddressing=ipv6
IPv6PrivacyExtensions=yes

IPv4Forwarding=yes
IPv6Forwarding=yes

# DNS for systemd-resolved
DNS=192.168.1.1
#DNS=8.8.8.8
#DNS=8.8.4.4

[DHCPv4] 
UseMTU=true
EOL


echo "config lan..."
sudo tee /etc/systemd/network/10-lan.network > /dev/null << EOL
[Match]
Name=enp4s*

[Network]
Address=192.168.1.1/24
DNS=192.168.1.1

IPv4Forwarding=yes
IPv6Forwarding=yes
IPMasquerade=yes
EOL


# disable docker adding rules to nftables
# set routable ip range on docker network
echo "disable docker stuff..."
sudo tee /etc/docker/daemon.json > /dev/null << EOL
{
  "iptables" : false,
  "ip6tables" : false,
  "bip": "10.0.0.1/24",
  "fixed-cidr": "10.0.0.0/25",
  "default-address-pools": [
    {
      "base":"10.10.0.0/16",
      "size":24
    }
  ]
}
EOL


echo "restart network..."
sudo systemctl daemon-reload
sudo systemctl enable systemd-networkd --now
#sudo systemctl restart systemd-networkd
sudo systemctl disable NetworkManager

#ensure network is configured:
networkctl

echo ""
echo "enp* & usb0 should be routable & configured"
echo "make sure adguard is running for dhcp & DNS"
echo ""
echo "useful commands:"
echo "networkctl"
echo "networkctl status"
echo "networkctl status usb0"
echo ""
echo "you may need to restart the computer"
echo "done"













function fn_old {


### OLD ####


# enable forwarding/routing - can be done in the network files now?
#sudo nano /etc/sysctl.conf
#net.ipv4.ip_forward=1
#sysctl net.ipv4.conf.all.rp_filter=0
#sudo sysctl -p
#cat /proc/sys/net/ipv4/ip_forward



# armbian only, not arch
sudo apt install nftables
sudo systemctl enable nftables
sudo systemctl restart nftables

sudo apt remove netplan.io
sudo apt autoremove


# nftables routing
sudo mkdir /etc/nftables.d

sudo tee /etc/nftables.d/nat.conf > /dev/null << EOL
table inet filter {
        chain input {
                type filter hook input priority 0; policy accept;
        }
    
        chain forward {
                type filter hook forward priority filter; policy accept;
                #iifname "usb0" oifname "end0" ct state established,related accept
                #iifname "usb0" oifname "end0" accept # dont need?
                #iifname "end0" oifname "usb0" accept # dont need?
        }
}

table ip nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
        }

        chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                oifname "usb0" masquerade
        }
}
EOL



# todo: setup docker to work without needing host mode...
# this is the default rules for docker, but it breaks routing
sudo tee /etc/nftables.d/docker.conf.bk > /dev/null << EOL
table ip nat {
        chain DOCKER {
                iifname "docker0" counter packets 0 bytes 0 return
        }

        chain POSTROUTING {
                type nat hook postrouting priority srcnat; policy accept;
                ip saddr 172.17.0.0/16 oifname != "docker0" counter packets 0 bytes 0 masquerade
        }

        chain PREROUTING {
                type nat hook prerouting priority dstnat; policy accept;
                fib daddr type local counter packets 1 bytes 60 jump DOCKER
        }

        chain OUTPUT {
                type nat hook output priority dstnat; policy accept;
                ip daddr != 127.0.0.0/8 fib daddr type local counter packets 0 bytes 0 jump DOCKER
        }
}

table ip filter {
        chain DOCKER {
        }

        chain DOCKER-ISOLATION-STAGE-1 {
                iifname "docker0" oifname != "docker0" counter packets 0 bytes 0 jump DOCKER-ISOLATION-STAGE-2
                counter packets 0 bytes 0 return
        }

        chain DOCKER-ISOLATION-STAGE-2 {
                oifname "docker0" counter packets 0 bytes 0 drop
                counter packets 0 bytes 0 return
        }

        chain FORWARD {
                type filter hook forward priority filter; policy drop;
                counter packets 0 bytes 0 jump DOCKER-USER
                counter packets 0 bytes 0 jump DOCKER-ISOLATION-STAGE-1
                oifname "docker0" ct state related,established counter packets 0 bytes 0 accept
                oifname "docker0" counter packets 0 bytes 0 jump DOCKER
                iifname "docker0" oifname != "docker0" counter packets 0 bytes 0 accept
                iifname "docker0" oifname "docker0" counter packets 0 bytes 0 accept
        }

        chain DOCKER-USER {
                # todo, policy accpet here for routing??
                # type filter hook forward priority filter; policy accept;
                counter packets 0 bytes 0 return
        }
}

table ip6 nat {
        chain DOCKER {
        }
}

table ip6 filter {
        chain DOCKER {
        }

        chain DOCKER-ISOLATION-STAGE-1 {
                iifname "docker0" oifname != "docker0" counter packets 0 bytes 0 jump DOCKER-ISOLATION-STAGE-2
                counter packets 0 bytes 0 return
        }

        chain DOCKER-ISOLATION-STAGE-2 {
                oifname "docker0" counter packets 0 bytes 0 drop
                counter packets 0 bytes 0 return
        }

        chain FORWARD {
                type filter hook forward priority filter; policy drop;
                counter packets 0 bytes 0 jump DOCKER-USER
        }

        chain DOCKER-USER {
                counter packets 0 bytes 0 return
        }
}
EOL


# add include to the bottom of nftables.conf
echo 'include "/etc/nftables.d/*.conf"' | sudo tee -a /etc/nftables.conf
sudo nft -f /etc/nftables.conf
#sudo nft -f /etc/nftables.d/nat.conf
sudo nft list ruleset


















# should no need this eventually.... 

# udev to run system nft rules service
sudo tee /etc/systemd/system/internet-usb.service > /dev/null << EOL
[Unit]
Description=Run nftables on usb device connect
After=network.target

[Service]
ExecStart=/usr/sbin/nft -f /etc/nftables.conf
Type=oneshot
User=root
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOL

sudo tee /etc/udev/rules.d/99-internet-usb.rules > /dev/null << EOL
SUBSYSTEMS=="usb", ACTION=="add", ATTR{idVendor}=="18d1", ATTR{idProduct}=="4eec", RUN+="/usr/bin/systemctl start internet-usb.service"
EOL

sudo systemctl daemon-reload
sudo systemctl enable internet-usb.service
sudo udevadm control --reload-rules
sudo udevadm trigger








# more advanced firewall example
sudo tee /etc/nftables.d/net.conf.bk > /dev/null << EOL
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


}

