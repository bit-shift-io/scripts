#!/bin/bash

# This script disable suspend in order to let audio work with Zigbee on my server

# Source: https://forum.manjaro.org/t/howto-disable-turn-off-hibernate-completely/8033

# this script doesnt work,
# https://www.tutorialspoint.com/how-to-disable-suspend-and-hibernation-modes-in-linux

# https://www.tecmint.com/disable-suspend-and-hibernation-in-linux/



sudo mkdir -p "/etc/systemd/sleep.conf.d"

sudo bash -c "cat > /etc/systemd/sleep.conf.d/no-hibernate.conf" << EOL 
    [Sleep]
    # disable hibernation
    # doc : https://archived.forum.manjaro.org/t/turn-off-disable-hibernate-completely/139939
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
EOL

sudo mkdir -p "/etc/systemd/logind.conf.d"

sudo bash -c "cat > /etc/systemd/logind.conf.d/no-hibernate.conf" << EOL 
    [Login]
    # disable hibernation
    HibernateKeyIgnoreInhibited=no
EOL

# perform the test
echo "You should see the error: 'Call to Hibernate failed: Sleep verb "hibernate" not supported'"
sudo systemctl hibernate
