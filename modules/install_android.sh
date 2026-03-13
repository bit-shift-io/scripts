#!/bin/bash


echo "installing..."
../util.sh -i waydroid binder_linux-dkms #weston #wayfire


echo "sddm config..."
tee $HOME/.config/weston.ini > /dev/null << EOL
[libinput]
enable-tap=true

[shell]
panel-position=none
EOL

#/usr/share/xsessions/
# run via konsole for now as there is a bug
# https://github.com/waydroid/waydroid/issues/1052
sudo tee /usr/bin/waydroid-session.sh > /dev/null << EOL
#!/bin/sh
#weston &
kwin_wayland &
sleep 1
export WAYLAND_DISPLAY=wayland-0
export DISPLAY=:1
#konsole -e /usr/bin/waydroid show-full-ui
waydroid show-full-ui
EOL

sudo chmod +x /usr/bin/waydroid-session.sh

sudo tee /usr/share/wayland-sessions/android-tv.desktop > /dev/null << EOL
[Desktop Entry]
Name=Android
Comment=Android
Exec=/usr/bin/waydroid-session.sh
Type=Application
EOL


echo "download/init android image..."

# remove these dirs so waydroid can download its own images
sudo rm -r /etc/waydroid-extra
sudo rm -r /usr/share/waydroid-extra

# download custom image
cd $HOME
sudo waydroid init -s GAPPS
sudo waydroid init -f


echo "installing extra android stuff..."

# install gapps
#curl -L https://github.com/Waydroid-ATV/androidtv_scripts/raw/refs/heads/main/install-mindthegapps.sh | sudo bash -eu

# install widevine
#curl -L https://github.com/Waydroid-ATV/androidtv_scripts/raw/refs/heads/main/install-widevine-a13.sh | sudo bash -eu

# start a session
waydroid show-full-ui

echo "Complete"
