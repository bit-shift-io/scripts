#!/usr/bin/env bash

# Power Profile & Boot Service Manager for AMD Ryzen AI 9 HX 370 (Radeon 890M)

set -e

GPU_CARD="/sys/class/drm/card1/device/power_dpm_force_performance_level"
BOOT_SCRIPT="/usr/local/bin/gpu-low-power-boot.sh"
SERVICE_FILE="/etc/systemd/system/gpu-low-power.service"

show_menu() {
    clear
    echo "    AMD Ryzen AI 9 HX 370 Power Menu      "
    echo "=========================================="
    echo "1) Low Power Mode  (Enable Boot Service & Silent Mode)"
    echo "2) Standard Mode   (Remove Boot Service & Reset Defaults)"
    echo "3) Show Current Status"
    echo "4) Exit"
    read -p "Select an option [1-4]: " choice
}

install_boot_service() {
    echo "  -> Creating boot script at $BOOT_SCRIPT..."
    sudo bash -c "cat << 'EOF' > $BOOT_SCRIPT
#!/usr/bin/env bash
sleep 2
GPU_CARD=\"/sys/class/drm/card1/device/power_dpm_force_performance_level\"
if [ -f \"\$GPU_CARD\" ]; then
    echo \"low\" > \"\$GPU_CARD\"
fi
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set power-saver
fi
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
    echo \"power\" | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null
fi
if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
    echo \"0\" > /sys/devices/system/cpu/cpufreq/boost
fi
EOF"
    sudo chmod +x "$BOOT_SCRIPT"

    echo "  -> Creating systemd service at $SERVICE_FILE..."
    sudo bash -c "cat << 'EOF' > $SERVICE_FILE
[Unit]
Description=Set Low Power Mode on Boot (Fix Coil Whine)
After=multi-user.target graphical.target

[Service]
Type=oneshot
ExecStart=$BOOT_SCRIPT

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable gpu-low-power.service
    echo "  -> Systemd service installed and enabled for persistent boot."
}

remove_boot_service() {
    if [ -f "$SERVICE_FILE" ]; then
        echo "  -> Disabling and removing systemd boot service..."
        sudo systemctl disable --now gpu-low-power.service 2>/dev/null || true
        sudo rm -f "$SERVICE_FILE"
        sudo rm -f "$BOOT_SCRIPT"
        sudo systemctl daemon-reload
        echo "  -> Boot service removed."
    else
        echo "  -> No active boot service found to remove."
    fi
}

apply_low_power() {
    echo -e "\n[+] Switching to Low Power Mode..."

    # Apply runtime settings immediately
    if command -v powerprofilesctl &> /dev/null; then
        sudo powerprofilesctl set power-saver
    fi

    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
        echo "power" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null
    fi

    if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
        echo "0" | sudo tee /sys/devices/system/cpu/cpufreq/boost > /dev/null
    fi

    if [ -f "$GPU_CARD" ]; then
        echo "low" | sudo tee "$GPU_CARD" > /dev/null
    fi

    # Set up persistence across reboots
    install_boot_service

    echo "[-] Low Power Mode active (will persist on reboot)."
}

apply_standard() {
    echo -e "\n[+] Resetting to Standard / Default Mode..."

    # Restore runtime defaults immediately
    if command -v powerprofilesctl &> /dev/null; then
        sudo powerprofilesctl set balanced
    fi

    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
        echo "balance_performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null
    fi

    if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
        echo "1" | sudo tee /sys/devices/system/cpu/cpufreq/boost > /dev/null
    fi

    if [ -f "$GPU_CARD" ]; then
        echo "auto" | sudo tee "$GPU_CARD" > /dev/null
    fi

    # Remove the boot service so default behavior handles reboots
    remove_boot_service

    echo "[-] Standard defaults restored (boot service removed)."
}

show_status() {
    echo -e "\n--- Current System Status ---"
    if command -v powerprofilesctl &> /dev/null; then
        echo -n "Active Profile:          "
        powerprofilesctl get
    fi

    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
        echo -n "EPP Hint (CPU 0):        "
        cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
    fi

    if [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
        echo -n "CPU Boost Enabled:      "
        cat /sys/devices/system/cpu/cpu/boost 2>/dev/null || cat /sys/devices/system/cpu/cpufreq/boost
    fi

    if [ -f "$GPU_CARD" ]; then
        echo -n "iGPU DPM Level (card1):  "
        cat "$GPU_CARD"
    fi

    echo -n "Boot Service Active:     "
    if systemctl is-enabled gpu-low-power.service &>/dev/null; then
        echo "Enabled"
    else
        echo "Disabled / Not Present"
    fi
    echo "-----------------------------"
    read -p "Press Enter to continue..."
}

while true; do
    show_menu
    case $choice in
        1) apply_low_power; sleep 2 ;;
        2) apply_standard; sleep 2 ;;
        3) show_status ;;
        4) exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
