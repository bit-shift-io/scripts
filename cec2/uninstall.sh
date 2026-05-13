#!/bin/bash

# CEC2 Uninstall Script
# Removes all CEC2 services and cleans up experimental installations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== CEC2 Uninstall ===${NC}\n"
echo -e "${RED}WARNING: This will remove all CEC2 services${NC}\n"

# Confirm
read -p "Are you sure you want to uninstall CEC2? (y/N): " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstall cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}Removing services...${NC}\n"

# Disable and stop user service
echo "Stopping user service..."
systemctl --user disable cec_daemon.service 2>/dev/null || true
systemctl --user stop cec_daemon.service 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true
echo "✓ User service stopped"

# Remove user service file
echo "Removing user service file..."
rm -f ~/.config/systemd/user/cec_daemon.service
echo "✓ User service file removed"

# Remove experimental system services (if any exist from testing)
echo ""
echo "Removing experimental system services..."

# Stop and remove ACPI monitor
sudo systemctl disable acpi-wake-monitor.service 2>/dev/null || true
sudo systemctl stop acpi-wake-monitor.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/acpi-wake-monitor.service
echo "✓ ACPI monitor removed"

# Stop and remove sleep daemon
sudo systemctl disable cec-sleep-daemon.service 2>/dev/null || true
sudo systemctl stop cec-sleep-daemon.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/cec-sleep-daemon.service
echo "✓ Sleep daemon removed"

# Remove sleep hooks
sudo rm -f /usr/lib/systemd/system-sleep/cec-wake-detector
echo "✓ Sleep hooks removed"

# Reload systemd
sudo systemctl daemon-reload 2>/dev/null || true
echo ""

# Remove log files
echo "Cleaning up log files..."
sudo rm -f /var/log/cec-wake-detection.log
sudo rm -f /var/log/cec-daemon.log
echo "✓ Log files removed"

echo ""
echo -e "${GREEN}=== Uninstall Complete ===${NC}"
echo ""
echo "Removed:"
echo "  • User service: ~/.config/systemd/user/cec_daemon.service"
echo "  • System services: acpi-wake-monitor, cec-sleep-daemon"
echo "  • Sleep hooks: /usr/lib/systemd/system-sleep/cec-wake-detector"
echo "  • Log files: /var/log/cec-*.log"
echo ""
echo "The following files remain in the cec2 directory:"
echo "  • Source code (cec_daemon.py, *.sh)"
echo "  • Documentation (README.md, RESEARCH_LOG.md, etc.)"
echo ""
echo "To remove the entire cec2 directory:"
echo "  rm -rf $(cd "$(dirname "$0")" && pwd)"
echo ""
