#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

# disable broken kde search
#if command -v balooctl > /dev/null 2>&1; then
#    balooctl disable
#fi

# kde fullscreen spaces
cd /tmp/
git clone https://github.com/geodro/kde-fullscreen-spaces.git
cd kde-fullscreen-spaces
./install.sh

# install software
echo -e '\n\nInstalling packages...'
"$UTIL" -i partitionmanager skanlite filelight kio-extras plasma-browser-integration isoimagewriter okular skanpage krdc krdp


#
# YAKUAKE
#
echo "Yakuake..."
"$UTIL" -i yakuake

mkdir -p $HOME/.local/share/kio/servicemenus/

# Find the right binary on CachyOS
if command -v qdbus6 &> /dev/null; then
    DBUS_CMD="qdbus6"
elif command -v qdbus-qt6 &> /dev/null; then
    DBUS_CMD="qdbus-qt6"
elif command -v qdbus &> /dev/null; then
    DBUS_CMD="qdbus"
else
    echo "Error: qdbus tools not found. Trying to install..."
    #sudo pacman -S --needed qt6-tools
    DBUS_CMD="qdbus6"
fi

echo "dbus found: $DBUS_CMD"

echo "config..."
tee $HOME/.local/share/kio/servicemenus/yakuake_run.desktop > /dev/null << EOL
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-executable;
Actions=runInYakuake;
X-KDE-AuthorizeAction=shell_access

[Desktop Action runInYakuake]
Name=Run in Yakuake
Icon=yakuake
Exec=sh -c "$DBUS_CMD org.kde.yakuake /yakuake/window toggleWindowState && $DBUS_CMD org.kde.yakuake /yakuake/sessions runCommand 'clear && %f'"
EOL

chmod +x $HOME/.local/share/kio/servicemenus/yakuake_run.desktop
kbuildsycoca6 --noincremental
#desktop-file-validate $HOME/.local/share/kio/servicemenus/yakuake_run.desktop
#
# END
#

notify 'Config' 'KDE config complete'
