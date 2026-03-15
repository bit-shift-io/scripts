#!/usr/bin/env bash

set -e

echo "== Laptop Power Optimization Script (Arch / EndeavourOS) =="

# ---- SETTINGS ----
PL1=12000000   # 12W sustained
PL2=15000000   # 15W turbo

echo "Installing powertop & tlp..."
sudo pacman -Sy --needed --noconfirm powertop tlp tlp-pd

# disable kde power tool
systemctl mask power-profiles-daemon
systemctl stop power-profiles-daemon

systemctl enable --now tlp
systemctl enable --now tlp-pd

# shouldnt need this with TLP
#echo "Creating CPU power limit systemd service..."
#sudo tee /etc/systemd/system/cpu-power-limit.service > /dev/null <<EOF
#[Unit]
#Description=CPU Power Limit
#
#[Service]
#Type=oneshot
#ExecStart=/bin/sh -c "echo $PL1 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw"
#ExecStart=/bin/sh -c "echo $PL2 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw"
#
#[Install]
#WantedBy=multi-user.target
#EOF
#sudo systemctl enable cpu-power-limit


#echo "Creating Powertop auto-tune service..."
#sudo tee /etc/systemd/system/powertop.service > /dev/null <<EOF
#[Unit]
#Description=Powertop tunings
#
#[Service]
#Type=oneshot
#ExecStart=/usr/bin/powertop --auto-tune
#
#[Install]
#WantedBy=multi-user.target
#EOF
#sudo systemctl enable powertop



#echo "Configuring systemd-boot kernel parameters..."
#ACTIVE_ENTRY=$(sudo bootctl status | awk -F': ' '/Current Entry/ {print $2}')
#BOOT_ENTRY="/efi/loader/entries/$ACTIVE_ENTRY"
#KERNEL_PARAMS="pcie_aspm=force i915.enable_psr=1 i915.enable_rc6=7 i915.enable_fbc=1"
#KERNEL_PARAMS="i915.enable_psr=1 i915.enable_rc6=7 i915.enable_fbc=1"

# Check if all parameters are already present
#MISSING_PARAMS=""
#for param in $KERNEL_PARAMS; do
#    if ! sudo grep -q "$param" "$BOOT_ENTRY"; then
#        MISSING_PARAMS="$MISSING_PARAMS $param"
#    fi
#done

#if [[ -z "$MISSING_PARAMS" ]]; then
#    echo "All kernel parameters already present."
#else
#    echo "Adding missing kernel parameters:$MISSING_PARAMS"
#    sudo sed -i "s/options \(.*\)/options \1$MISSING_PARAMS/" "$BOOT_ENTRY"
#    echo "Kernel parameters updated. Reboot required to apply."
#fi


echo "Done!"
echo
echo "Reboot your system to apply all changes."
