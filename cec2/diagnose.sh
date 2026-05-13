#!/bin/bash

# CEC2 Sleep Detection Setup Script
# Sets up systemd sleep target services and reports status

set -e

echo "=== CEC2 Sleep Detection Setup ==="
echo ""
echo "Timestamp: $(date)"
echo ""

DIR="/home/server/Projects/scripts/cec2"

echo "--- Step 1: Verify Prerequisites ---"
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

echo "--- Step 2: Create systemd sleep services ---"
mkdir -p ~/.config/systemd/user

echo "Creating cec-sleep-before.service..."
tee ~/.config/systemd/user/cec-sleep-before.service > /dev/null << 'EOFBEFORE'
[Unit]
Description=CEC - Turn off TV before sleep
Before=sleep.target

[Service]
Type=oneshot
ExecStart=/home/server/Projects/scripts/cec2/aboutToTurnOff.sh
RemainAfterExit=yes

[Install]
WantedBy=sleep.target
EOFBEFORE

echo "Creating cec-sleep-after.service..."
tee ~/.config/systemd/user/cec-sleep-after.service > /dev/null << 'EOFAFTER'
[Unit]
Description=CEC - Turn on TV after sleep
After=sleep.target

[Service]
Type=oneshot
ExecStart=/home/server/Projects/scripts/cec2/wakeUp.sh
RemainAfterExit=yes

[Install]
WantedBy=sleep.target
EOFAFTER

echo "✓ Sleep services created"
echo ""

echo "--- Step 3: Reload systemd and enable services ---"
systemctl --user daemon-reload
systemctl --user enable cec-sleep-before.service cec-sleep-after.service
echo "✓ Services enabled"
echo ""

echo "--- Step 4: Check service status ---"
echo ""
echo "Before-sleep service:"
systemctl --user status cec-sleep-before.service || true
echo ""
echo "After-sleep service:"
systemctl --user status cec-sleep-after.service || true
echo ""

echo "--- Step 5: Check current ScreenSaver service ---"
systemctl --user status cec_daemon.service
echo ""

echo "--- Step 6: Recent logs ---"
echo "User service recent logs:"
journalctl --user -u cec_daemon -n 10
echo ""

echo "=== SETUP COMPLETE ==="
echo ""
echo "Next: TEST SLEEP/WAKE DETECTION"
echo ""
echo "Run this command in a new terminal:"
echo "  journalctl --user -f --since now"
echo ""
echo "Then:"
echo "  1. Put your system to sleep"
echo "  2. Wake it up"
echo "  3. Log in"
echo "  4. Check the logs from step 1"
echo ""
echo "You should see cec-sleep-before and cec-sleep-after services"
echo "being started/stopped, and the TV should turn on before login."
echo ""
echo "If it doesn't work, run:"
echo "  systemctl --user status cec-sleep-before.service"
echo "  systemctl --user status cec-sleep-after.service"
echo "  journalctl --user -u cec-sleep-before -n 20"
echo "  journalctl --user -u cec-sleep-after -n 20"
