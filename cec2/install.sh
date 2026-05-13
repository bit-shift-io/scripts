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

# Show status
echo -e "${YELLOW}User service status:${NC}"
systemctl --user status cec_daemon.service

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "\n${YELLOW}Features:${NC}"
echo "  ✓ Screen on/off detection (via user service)"
echo "  ✓ Sleep/wake detection (via system sleep hook)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  - Check the user service status: systemctl --user status cec_daemon"
echo "  - View user service logs: journalctl --user -u cec_daemon -f"
echo "  - View sleep/wake logs: sudo journalctl -u cec-sleep -f OR sudo tail -f /var/log/cec_daemon.log"
echo ""
echo -e "${YELLOW}To uninstall:${NC}"
echo "  - systemctl --user disable cec_daemon.service"
echo "  - systemctl --user stop cec_daemon.service"
echo "  - sudo rm /etc/systemd/system-sleep/cec-sleep"
echo ""
