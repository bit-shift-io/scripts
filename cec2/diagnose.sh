#!/bin/bash

# CEC2 Complete Setup & Diagnostic Script
# Installs: user service (screen on/off), systemd-sleep hook (guaranteed wake detection), ACPI monitor (real-time wake events)

set -e

echo "=== CEC2 Complete Setup - Dual Wake Detection ==="
echo ""
echo "Timestamp: $(date)"
echo ""

DIR="/home/server/Projects/scripts/cec2"

echo "--- Step 1: Verify Prerequisites ---"
for file in cec_daemon.py cec-sleep-daemon.py aboutToTurnOff.sh wakeUp.sh systemd-sleep-hook acpi-wake-monitor.sh; do
    if [ ! -f "$DIR/$file" ]; then
        echo "✗ $file not found"
        exit 1
    fi
done
echo "✓ All scripts found"

if ! command -v cec-client &> /dev/null; then
    echo "✗ cec-client not found"
    exit 1
fi
echo "✓ cec-client found"

if ! command -v acpi_listen &> /dev/null; then
    echo "⚠ acpi_listen not found (optional, will install)"
    INSTALL_ACPI=1
else
    echo "✓ acpi_listen found"
fi
echo ""

echo "--- Step 2: Install optional dependencies ---"
if [ "$INSTALL_ACPI" = "1" ]; then
    echo "Installing acpi package for ACPI event monitoring..."
    sudo pacman -S --noconfirm acpi acpid 2>/dev/null || \
    sudo apt-get install -y acpi acpid 2>/dev/null || \
    echo "⚠ Could not install acpi (not critical)"
fi

sudo systemctl enable acpid 2>/dev/null || true
sudo systemctl start acpid 2>/dev/null || true
echo "✓ Dependencies checked"
echo ""

echo "--- Step 3: Create log file ---"
sudo touch /var/log/cec-wake-detection.log
sudo chmod 666 /var/log/cec-wake-detection.log
echo "✓ Log file created: /var/log/cec-wake-detection.log"
echo ""

echo "--- Step 4: Make all scripts executable ---"
chmod +x "$DIR/cec_daemon.py" "$DIR/cec-sleep-daemon.py" "$DIR/aboutToTurnOff.sh" "$DIR/wakeUp.sh" \
         "$DIR/systemd-sleep-hook" "$DIR/acpi-wake-monitor.sh"
echo "✓ All scripts executable"
echo ""

echo "--- Step 5: Setup User Service (Screen On/Off Detection) ---"
mkdir -p ~/.config/systemd/user

tee ~/.config/systemd/user/cec_daemon.service > /dev/null << 'EOFUSER'
[Unit]
Description=CEC Daemon - Turn TV/Monitor on/off with KDE Plasma
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/server/Projects/scripts/cec2/cec_daemon.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOFUSER

systemctl --user daemon-reload
systemctl --user enable cec_daemon.service
systemctl --user restart cec_daemon.service
echo "✓ User service enabled"
echo ""

echo "--- Step 6: Install systemd-sleep hook (PRIMARY wake detection) ---"
sudo install -D -m 0755 "$DIR/systemd-sleep-hook" "/usr/lib/systemd/system-sleep/cec-wake-detector"
echo "✓ Sleep hook installed at /usr/lib/systemd/system-sleep/cec-wake-detector"
echo ""

echo "--- Step 7: Install ACPI monitor service (SECONDARY wake detection) ---"
sudo tee /etc/systemd/system/acpi-wake-monitor.service > /dev/null << 'EOFACPI'
[Unit]
Description=CEC ACPI Wake Event Monitor
After=acpid.service dbus.service
Wants=acpid.service

[Service]
Type=simple
ExecStart=/bin/bash /home/server/Projects/scripts/cec2/acpi-wake-monitor.sh
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFACPI

sudo systemctl daemon-reload
sudo systemctl enable acpi-wake-monitor.service
sudo systemctl restart acpi-wake-monitor.service
echo "✓ ACPI monitor service enabled"
echo ""

echo "--- Step 8: Clean up old services ---"
systemctl --user disable cec-sleep-before.service 2>/dev/null || true
systemctl --user disable cec-sleep-after.service 2>/dev/null || true
systemctl --user stop cec-sleep-before.service 2>/dev/null || true
systemctl --user stop cec-sleep-after.service 2>/dev/null || true
sudo systemctl disable cec-sleep-daemon.service 2>/dev/null || true
sudo systemctl stop cec-sleep-daemon.service 2>/dev/null || true
rm -f ~/.config/systemd/user/cec-sleep-before.service ~/.config/systemd/user/cec-sleep-after.service
echo "✓ Old services cleaned up"
echo ""

echo "--- Step 9: Service Status ---"
echo ""
echo "User Service (Screen On/Off):"
systemctl --user status cec_daemon.service | head -8
echo ""
echo "ACPI Monitor Service (Wake Events):"
sudo systemctl status acpi-wake-monitor.service | head -8
echo ""

echo "--- Step 10: Verify Installation ---"
echo ""
echo "Systemd-sleep hook:"
if [ -f /usr/lib/systemd/system-sleep/cec-wake-detector ]; then
    echo "  ✓ Installed at /usr/lib/systemd/system-sleep/cec-wake-detector"
else
    echo "  ✗ NOT found"
fi

echo ""
echo "ACPI monitor service:"
if [ -f /etc/systemd/system/acpi-wake-monitor.service ]; then
    echo "  ✓ Installed"
else
    echo "  ✗ NOT installed"
fi

echo ""
echo "Log file:"
if [ -f /var/log/cec-wake-detection.log ]; then
    echo "  ✓ Created: /var/log/cec-wake-detection.log"
fi
echo ""

echo "=== SETUP COMPLETE ==="
echo ""
echo "THREE DETECTION METHODS NOW ACTIVE:"
echo ""
echo "1. USER SERVICE (cec_daemon) - Screen on/off detection"
echo "   • Detects when screen blanks/activates"
echo "   • Runs when logged in"
echo "   • Status: $(systemctl --user is-active cec_daemon.service)"
echo ""
echo "2. SYSTEMD-SLEEP HOOK (PRIMARY) - System wake detection"
echo "   • Guaranteed to run on suspend/resume"
echo "   • Runs at system level"
echo "   • Location: /usr/lib/systemd/system-sleep/cec-wake-detector"
echo ""
echo "3. ACPI MONITOR (SECONDARY) - Real-time wake events"
echo "   • Listens for ACPI power events"
echo "   • Runs as system service"
echo "   • Status: $(sudo systemctl is-active acpi-wake-monitor.service)"
echo ""

echo "=== TESTING INSTRUCTIONS ==="
echo ""
echo "Watch all logs in real-time:"
echo ""
echo "  Terminal 1 - All wake detection logs:"
echo "    sudo tail -f /var/log/cec-wake-detection.log"
echo ""
echo "  Terminal 2 - User service (screen):"
echo "    journalctl --user -u cec_daemon -f"
echo ""
echo "  Terminal 3 - System journal:"
echo "    sudo journalctl -f | grep -i 'cec\|acpi\|sleep'"
echo ""
echo "Then perform this sequence:"
echo "  1. Put system to sleep (Ctrl+Alt+S or power menu)"
echo "  2. Wait 5 seconds"
echo "  3. Wake system (move mouse or press key)"
echo "  4. Watch the logs - you should see wake detection"
echo "  5. TV should turn ON"
echo "  6. Log in"
echo "  7. TV should respond to screen lock/unlock"
echo ""

echo "=== QUICK DIAGNOSTICS ==="
echo ""
echo "Check which detection method works:"
echo "  grep 'DETECTED' /var/log/cec-wake-detection.log"
echo ""
echo "View latest wake events:"
echo "  sudo tail -20 /var/log/cec-wake-detection.log"
echo ""
echo "Check acpid status:"
echo "  sudo systemctl status acpid"
echo ""
echo "Listen for ACPI events manually:"
echo "  acpi_listen"
