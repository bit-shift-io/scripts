#!/bin/bash

# Setup CEC Sleep Daemon
# Installs system-level daemon to detect sleep/wake before login

set -e

echo "=== CEC Sleep Daemon Setup ==="
echo ""

DIR="/home/server/Projects/scripts/cec2"

echo "--- Verifying prerequisites ---"
if [ ! -x "$DIR/cec-sleep-daemon.py" ]; then
    echo "✗ cec-sleep-daemon.py not found or not executable"
    exit 1
fi
echo "✓ cec-sleep-daemon.py found"

if [ ! -x "$DIR/aboutToTurnOff.sh" ]; then
    echo "✗ aboutToTurnOff.sh not found"
    exit 1
fi
echo "✓ aboutToTurnOff.sh found"

if [ ! -x "$DIR/wakeUp.sh" ]; then
    echo "✗ wakeUp.sh not found"
    exit 1
fi
echo "✓ wakeUp.sh found"

if ! command -v cec-client &> /dev/null; then
    echo "✗ cec-client not found"
    exit 1
fi
echo "✓ cec-client found"

echo ""
echo "--- Installing system service ---"

sudo tee /etc/systemd/system/cec-sleep-daemon.service > /dev/null << 'EOF'
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
EOF

echo "✓ Service file created"

echo ""
echo "--- Enabling and starting service ---"
sudo systemctl daemon-reload
sudo systemctl enable cec-sleep-daemon.service
sudo systemctl restart cec-sleep-daemon.service

echo "✓ Service enabled and started"

echo ""
echo "--- Service Status ---"
sudo systemctl status cec-sleep-daemon.service

echo ""
echo "--- Cleaning up old services ---"
echo "Disabling user sleep services (no longer needed)..."
systemctl --user disable cec-sleep-before.service cec-sleep-after.service 2>/dev/null || true
systemctl --user stop cec-sleep-before.service cec-sleep-after.service 2>/dev/null || true

echo ""
echo "=== Setup Complete ==="
echo ""
echo "The system-level CEC Sleep Daemon is now running."
echo "It will:"
echo "  • Turn off TV when system goes to sleep"
echo "  • Turn on TV when system wakes (even before login)"
echo "  • Continue detecting screen on/off via user service"
echo ""
echo "Testing:"
echo "  1. Watch logs: sudo journalctl -u cec-sleep-daemon -f"
echo "  2. Put system to sleep"
echo "  3. Wake system (TV should turn on at login screen)"
echo "  4. Log in (screen should turn on via user service)"
echo ""
echo "Status commands:"
echo "  sudo systemctl status cec-sleep-daemon"
echo "  sudo journalctl -u cec-sleep-daemon -n 20"
echo "  sudo tail -f /var/log/cec-sleep-daemon.log"
