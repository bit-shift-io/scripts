#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CEC2 Daemon Installer ===${NC}\n"

# Check if running on Arch/Arch-based system
if ! command -v pacman &> /dev/null; then
    echo -e "${YELLOW}Warning: This install script is optimized for Arch Linux.${NC}"
    echo -e "${YELLOW}You may need to manually install the dependencies for your distribution.${NC}"
fi

# Install required tools
echo -e "${YELLOW}Installing dependencies...${NC}"
if command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm \
        libcec \
        python-dbus \
        python-gobject
else
    echo -e "${YELLOW}Please install these packages manually:${NC}"
    echo "  - libcec"
    echo "  - python-dbus"
    echo "  - python-gobject"
fi

echo -e "${GREEN}Dependencies installed${NC}\n"

# Make scripts executable
echo -e "${YELLOW}Setting up scripts...${NC}"
DIR="$( cd "$( dirname "$0" )" && pwd )"
chmod +x "$DIR/cec_daemon.py"
chmod +x "$DIR/aboutToTurnOff.sh"
chmod +x "$DIR/wakeUp.sh"
chmod +x "$DIR/cec-sleep"
echo -e "${GREEN}Scripts made executable${NC}\n"

# Install systemd user service for screen on/off detection
echo -e "${YELLOW}Installing systemd user service...${NC}"
mkdir -p "$HOME/.config/systemd/user"
tee "$HOME/.config/systemd/user/cec_daemon.service" > /dev/null << EOL
[Unit]
Description=CEC Daemon - Turn TV/Monitor on/off with KDE Plasma
Documentation=file://${DIR}/README.md
After=dbus.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 ${DIR}/cec_daemon.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOL

echo -e "${GREEN}User service file created${NC}\n"

# Install systemd sleep hook for sleep/wake detection
echo -e "${YELLOW}Installing systemd sleep hook...${NC}"
sudo mkdir -p /etc/systemd/system-sleep
sudo tee /etc/systemd/system-sleep/cec-sleep > /dev/null << 'EOL'
#!/bin/bash
SCRIPT_DIR="$DIR"
case "$1" in
  pre)
    echo "$(date) - System going to sleep, turning off TV" >> /var/log/cec_daemon.log 2>&1
    "$SCRIPT_DIR/aboutToTurnOff.sh" >> /var/log/cec_daemon.log 2>&1
    ;;
  post)
    echo "$(date) - System waking up, turning on TV" >> /var/log/cec_daemon.log 2>&1
    "$SCRIPT_DIR/wakeUp.sh" >> /var/log/cec_daemon.log 2>&1
    ;;
esac
EOL

# Make sleep hook executable
sudo chmod +x /etc/systemd/system-sleep/cec-sleep
# Fix the script path in the sleep hook
sudo sed -i "s|\$DIR|${DIR}|g" /etc/systemd/system-sleep/cec-sleep

echo -e "${GREEN}Sleep hook installed${NC}\n"

# Enable and start the user service
echo -e "${YELLOW}Enabling and starting the user service...${NC}"
systemctl --user daemon-reload
systemctl --user enable cec_daemon.service
systemctl --user restart cec_daemon.service

echo -e "${GREEN}User service started${NC}\n"

# Give services a moment to start
sleep 2

# Check user service status
echo -e "${YELLOW}Checking user service status:${NC}"
if systemctl --user is-active --quiet cec_daemon.service; then
    echo -e "${GREEN}✓ User service is running${NC}"
else
    echo -e "${RED}✗ User service failed to start${NC}"
    echo -e "${YELLOW}Debug: Recent logs:${NC}"
    journalctl --user -u cec_daemon -n 10
fi

# Check sleep hook exists
echo -e "\n${YELLOW}Checking sleep hook:${NC}"
if [ -x /etc/systemd/system-sleep/cec-sleep ]; then
    echo -e "${GREEN}✓ Sleep hook is installed and executable${NC}"
else
    echo -e "${RED}✗ Sleep hook missing or not executable${NC}"
fi

# Check if cec-client is available
echo -e "\n${YELLOW}Checking CEC tools:${NC}"
if command -v cec-client &> /dev/null; then
    echo -e "${GREEN}✓ cec-client found${NC}"
else
    echo -e "${RED}✗ cec-client not found (install libcec/cec-utils)${NC}"
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "\n${YELLOW}Features:${NC}"
echo "  ✓ Screen on/off detection (via user service)"
echo "  ✓ Sleep/wake detection (via system sleep hook)"
echo ""
echo -e "${YELLOW}Testing:${NC}"
echo "  1. Lock screen and watch: journalctl --user -u cec_daemon -f"
echo "  2. Sleep system and watch: sudo tail -f /var/log/cec_daemon.log"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "  - User service: journalctl --user -u cec_daemon -f"
echo "  - Sleep/wake: sudo tail -f /var/log/cec_daemon.log"
echo ""
