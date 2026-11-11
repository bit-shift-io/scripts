#!/bin/bash
set -euo pipefail

# arduino
sudo tee /etc/udev/rules.d/01-ttyusb.rules > /dev/null << 'EOL'
SUBSYSTEMS=="usb-serial", TAG+="uaccess"
EOL

# NRF
sudo tee /etc/udev/rules.d/71-nrf.rules > /dev/null << 'EOL'
ACTION!="add", SUBSYSTEM!="usb_device", GOTO="nrf_rules_end"

# Set /dev/bus/usb/*/* as read-write for all users (0666) for Nordic Semiconductor devices
SUBSYSTEM=="usb", ATTRS{idVendor}=="1915", MODE="0666"

# Flag USB CDC ACM devices, handled later in 99-mm-nrf-blacklist.rules
# Set USB CDC ACM devnodes as read-write for all users
KERNEL=="ttyACM[0-9]*", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1915", MODE="0666", ENV{NRF_CDC_ACM}="1"

LABEL="nrf_rules_end"
EOL

# NRF
sudo tee /etc/udev/rules.d/99-mm-nrf-blacklist.rules > /dev/null << 'EOL'
# Previously flagged nRF USB CDC ACM devices shall be ignored by ModemManager
ENV{NRF_CDC_ACM}=="1", ENV{ID_MM_CANDIDATE}="0", ENV{ID_MM_DEVICE_IGNORE}="1"
EOL

# Raspberry Pi Debug Probe / Pico UART (CDC ACM, 2e8a:000c)
sudo tee /etc/udev/rules.d/72-rpi-debug-probe.rules > /dev/null << 'EOL'
ACTION!="add|change", GOTO="rpi_probe_end"
SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000c", MODE="0666", SYMLINK+="ttyPICO", ENV{ID_MM_DEVICE_IGNORE}="1"
LABEL="rpi_probe_end"
EOL

# load new udev rules
sudo udevadm control --reload
sudo udevadm trigger

# apply immediately to a probe that is already connected
for dev in /dev/ttyACM*; do
	[ -e "$dev" ] || continue
	if udevadm info -q property -n "$dev" 2>/dev/null | grep -qx 'ID_VENDOR_ID=2e8a'; then
		sudo chmod 666 "$dev"
	fi
done

# verify
ls -l /dev/ttyACM0 2>/dev/null || echo "No /dev/ttyACM0 present"
ls -l /dev/ttyPICO 2>/dev/null || echo "No /dev/ttyPICO symlink; replug the probe to create it"

echo "Done!"
