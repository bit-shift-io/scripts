#!/bin/bash


echo "installing..."
../util.sh -i yakuake

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
echo "Complete"
