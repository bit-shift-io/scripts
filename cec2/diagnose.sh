#!/bin/bash

# CEC2 Diagnostic Script
# Run this and share the output to debug sleep/wake detection issues

echo "=== CEC2 Sleep Hook Diagnostic ==="
echo ""
echo "Timestamp: $(date)"
echo ""

echo "--- 1. Sleep Hook File Check ---"
if [ -f /etc/systemd/system-sleep/cec-sleep ]; then
    echo "✓ Sleep hook file exists"
    echo "Permissions:"
    ls -la /etc/systemd/system-sleep/cec-sleep
    echo ""
    echo "Content:"
    cat /etc/systemd/system-sleep/cec-sleep
else
    echo "✗ Sleep hook file NOT found"
fi
echo ""

echo "--- 2. Manual Sleep Hook Test ---"
echo "Testing pre (sleep) action..."
sudo /etc/systemd/system-sleep/cec-sleep pre
echo "Testing post (wake) action..."
sudo /etc/systemd/system-sleep/cec-sleep post
echo ""

echo "--- 3. Log File Check ---"
echo "Current /var/log/cec_daemon.log (last 30 lines):"
sudo tail -30 /var/log/cec_daemon.log
echo ""

echo "--- 4. User Service Status ---"
systemctl --user status cec_daemon.service
echo ""

echo "--- 5. User Service Recent Logs ---"
journalctl --user -u cec_daemon -n 20
echo ""

echo "--- 6. System Logs Around Sleep ---"
echo "Recent systemd logs (last 30 lines):"
sudo journalctl -n 30 | grep -i "sleep\|cec\|suspend"
echo ""

echo "--- 7. CEC Client Availability ---"
if command -v cec-client &> /dev/null; then
    echo "✓ cec-client found at: $(which cec-client)"
else
    echo "✗ cec-client NOT found"
fi
echo ""

echo "--- 8. Script Availability ---"
DIR="/home/server/Projects/scripts/cec2"
if [ -x "$DIR/aboutToTurnOff.sh" ]; then
    echo "✓ aboutToTurnOff.sh is executable"
else
    echo "✗ aboutToTurnOff.sh is NOT executable"
fi

if [ -x "$DIR/wakeUp.sh" ]; then
    echo "✓ wakeUp.sh is executable"
else
    echo "✗ wakeUp.sh is NOT executable"
fi
echo ""

echo "=== END DIAGNOSTIC ==="
echo ""
echo "To test sleep/wake detection:"
echo "1. Run: sudo journalctl -f --since now | grep -i 'sleep\|cec'"
echo "2. Put system to sleep"
echo "3. Wake system and log in"
echo "4. Share the output from the journalctl window"
