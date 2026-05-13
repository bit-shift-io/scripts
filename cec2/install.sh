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
        cec-utils \
        python-dbus \
        python-gobject
else
    echo -e "${YELLOW}Please install these packages manually:${NC}"
    echo "  - cec-utils (or libcec)"
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
echo -e "${GREEN}Scripts made executable${NC}\n"

# Create cache directory for logs
mkdir -p "$HOME/.cache"

# Install systemd user service
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

echo -e "${GREEN}Service file created${NC}\n"

# Enable and start the service
echo -e "${YELLOW}Enabling and starting the service...${NC}"
systemctl --user daemon-reload
systemctl --user enable cec_daemon.service
systemctl --user restart cec_daemon.service

echo -e "${GREEN}Service started${NC}\n"

# Show status
echo -e "${YELLOW}Service status:${NC}"
systemctl --user status cec_daemon.service

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "  - Check the service status: systemctl --user status cec_daemon"
echo "  - View logs: journalctl --user -u cec_daemon -f"
echo "  - To uninstall: systemctl --user disable cec_daemon.service && systemctl --user stop cec_daemon.service"
echo ""
