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

# Pixel 5a (barbet) Phonewave boot userspace: ACM serial and ECM network
# (1d6b:0104). The serial is root:dialout 0660 by default; this makes it
# usable at once, and ttyBARBET names it the same across reboots.
sudo tee /etc/udev/rules.d/73-barbet-phone.rules > /dev/null << 'EOL'
ACTION!="add|change", GOTO="barbet_phone_end"
SUBSYSTEM=="tty", SUBSYSTEMS=="usb", KERNEL=="ttyACM[0-9]*", ATTRS{idVendor}=="1d6b", ATTRS{idProduct}=="0104", MODE="0666", SYMLINK+="ttyBARBET", ENV{ID_MM_DEVICE_IGNORE}="1"
LABEL="barbet_phone_end"
EOL

# Serial devices are root:dialout 0660. Group membership covers the ones the
# rules above do not, and takes effect at the next login.
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx dialout; then
	sudo usermod -aG dialout "$USER"
	echo "Added $USER to dialout; log in again for it to apply."
fi

# The Phonewave rescue puts the phone at 10.77.71.2/30 on its ECM interface.
# barbet-ncm already matches the phone; give the workstation the other side
# and keep this link out of the default route.
if nmcli -t -f NAME connection show | grep -qx 'barbet-ncm'; then
	sudo nmcli connection modify barbet-ncm \
		+ipv4.addresses 10.77.71.1/30 \
		ipv4.never-default yes
else
	sudo nmcli connection add type ethernet con-name barbet-ncm \
		ipv4.method manual \
		ipv4.addresses 172.16.42.2/24 \
		+ipv4.addresses 10.77.71.1/30 \
		ipv4.never-default yes
fi

# load new udev rules
sudo udevadm control --reload
sudo udevadm trigger

# apply immediately to a probe or phone that is already connected
for dev in /dev/ttyACM*; do
	[ -e "$dev" ] || continue
	case $(udevadm info -q property -n "$dev" 2>/dev/null) in
	*ID_VENDOR_ID=2e8a* | *ID_VENDOR_ID=1d6b*'ID_MODEL_ID=0104'*)
		sudo chmod 666 "$dev"
		;;
	esac
done

# reapply the phone's network profile so 10.77.71.1/30 is there now
nmcli -t -f NAME connection show | grep -qx 'barbet-ncm' &&
	sudo nmcli connection up barbet-ncm > /dev/null 2>&1 || true

# verify
ls -l /dev/ttyACM0 2>/dev/null || echo "No /dev/ttyACM0 present"
ls -l /dev/ttyPICO 2>/dev/null || echo "No /dev/ttyPICO symlink; replug the probe to create it"
ls -l /dev/ttyBARBET 2>/dev/null || echo "No /dev/ttyBARBET symlink; replug the phone to create it"

echo "Done!"
