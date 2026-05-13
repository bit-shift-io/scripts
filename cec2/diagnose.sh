#!/bin/bash

# CEC2 Complete Setup & Diagnostic Script
# Sets up all components: user service for screen on/off, system daemon for sleep/wake

set -e

echo "=== CEC2 Complete Setup & Diagnostic ==="
echo ""
echo "Timestamp: $(date)"
echo ""

DIR="/home/server/Projects/scripts/cec2"

echo "--- Step 1: Verify Prerequisites ---"
if [ ! -x "$DIR/cec-sleep-daemon.py" ]; then
    echo "✗ cec-sleep-daemon.py not found or not executable"
    exit 1
fi
echo "✓ cec-sleep-daemon.py found"

if [ ! -x "$DIR/aboutToTurnOff.sh" ]; then
    echo "✗ aboutToTurnOff.sh not found or not executable"
    exit 1
fi
echo "✓ aboutToTurnOff.sh is executable"

if [ ! -x "$DIR/wakeUp.sh" ]; then
    echo "✗ wakeUp.sh not found or not executable"
    exit 1
fi
echo "✓ wakeUp.sh is executable"

if ! command -v cec-client &> /dev/null; then
    echo "✗ cec-client not found"
    exit 1
fi
echo "✓ cec-client found"
echo ""

echo "--- Step 2: Disable old sleep services (if any) ---"
systemctl --user disable cec-sleep-before.service 2>/dev/null || true
systemctl --user disable cec-sleep-after.service 2>/dev/null || true
systemctl --user stop cec-sleep-before.service 2>/dev/null || true
systemctl --user stop cec-sleep-after.service 2>/dev/null || true
rm -f ~/.config/systemd/user/cec-sleep-before.service ~/.config/systemd/user/cec-sleep-after.service
echo "✓ Old services cleaned up"
echo ""

echo "--- Step 3: Setup User Service (Screen On/Off Detection) ---"
mkdir -p ~/.config/systemd/user

echo "Creating cec_daemon.service..."
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

echo "--- Step 4: Setup System Sleep Daemon (Sleep/Wake Detection) ---"
echo "Installing system sleep daemon..."

sudo tee /etc/systemd/system/cec-sleep-daemon.service > /dev/null << 'EOFSYSTEM'
[Unit]
Description=CEC Sleep Daemon - Detect sleep/wake and control TV
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/server/Projects/scripts/cec2/cec-sleep-daemon.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSYSTEM

sudo systemctl daemon-reload
sudo systemctl enable cec-sleep-daemon.service
sudo systemctl restart cec-sleep-daemon.service
echo "✓ System service enabled"
echo ""

echo "--- Step 5: Check Service Status ---"
echo ""
echo "User Service (Screen On/Off):"
systemctl --user status cec_daemon.service | head -10
echo ""
echo "System Service (Sleep/Wake):"
sudo systemctl status cec-sleep-daemon.service | head -10
echo ""

echo "--- Step 6: Check Availability ---"
if [ -f /etc/systemd/system/cec-sleep-daemon.service ]; then
    echo "✓ System sleep daemon service installed"
else
    echo "✗ System sleep daemon service NOT found"
fi

if [ -f ~/.config/systemd/user/cec_daemon.service ]; then
    echo "✓ User daemon service installed"
else
    echo "✗ User daemon service NOT found"
fi
echo ""

echo "--- Step 7: Recent Logs ---"
echo ""
echo "User service logs (last 5 lines):"
journalctl --user -u cec_daemon -n 5 || echo "No logs yet"
echo ""
echo "System daemon logs (last 5 lines):"
sudo journalctl -u cec-sleep-daemon -n 5 || echo "No logs yet"
echo ""

echo "=== SETUP COMPLETE ==="
echo ""
echo "Two-part system is now active:"
echo ""
echo "1. USER SERVICE (cec_daemon)"
echo "   • Detects screen on/off when logged in"
echo "   • Uses org.freedesktop.ScreenSaver DBus signals"
echo "   • Runs in your user session"
echo ""
echo "2. SYSTEM SERVICE (cec-sleep-daemon)"
echo "   • Detects system sleep/wake (before login)"
echo "   • Uses org.freedesktop.login1 signals"
echo "   • Runs at system level, stays active through sleep"
echo ""
echo "=== TESTING ==="
echo ""
echo "Run in a new terminal:"
echo "  sudo journalctl -u cec-sleep-daemon -f"
echo ""
echo "Then:"
echo "  1. Put system to sleep (Ctrl+Alt+S or power menu)"
echo "  2. TV should turn OFF"
echo "  3. Wake system (move mouse, press key)"
echo "  4. TV should turn ON at login screen"
echo "  5. Log in"
echo "  6. TV should stay on (or respond to screen locking)"
echo ""
echo "=== LOGS ==="
echo ""
echo "Screen on/off events:"
echo "  journalctl --user -u cec_daemon -f"
echo ""
echo "Sleep/wake events:"
echo "  sudo journalctl -u cec-sleep-daemon -f"
echo ""
echo "All CEC activity:"
echo "  sudo tail -f /var/log/cec-sleep-daemon.log"
