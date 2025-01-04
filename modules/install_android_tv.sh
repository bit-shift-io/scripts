#!/bin/bash


echo "installing..."
../util.sh -i waydroid binder_linux-dkms-git #weston #wayfire


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
Name=Android TV
Comment=Android
Exec=/usr/bin/waydroid-session.sh
Type=Application
EOL


echo "download android tv image..."

# download custom image
cd $HOME

wget -c https://github.com/supechicken/waydroid-androidtv-build/releases/download/20241215/lineage-20.0-20241215-UNOFFICIAL-SupeChicken666-WaydroidATV.zip

sudo mkdir -p /etc/waydroid-extra/images/
sudo unzip -o lineage-20.0-20241215-UNOFFICIAL-SupeChicken666-WaydroidATV.zip -d /etc/waydroid-extra/images/
sudo waydroid init -f


echo "installing extra android stuff..."

# install gapps
curl -L https://github.com/Waydroid-ATV/androidtv_scripts/raw/refs/heads/main/install-mindthegapps.sh | sudo bash -eu

# install widevine
curl -L https://github.com/Waydroid-ATV/androidtv_scripts/raw/refs/heads/main/install-widevine-a13.sh | sudo bash -eu

# start a session
waydroid session start

# certify
# need to do this manually after running waydroid first-launch

sudo waydroid shell
ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"
exit


echo "visit https://www.google.com/android/uncertified and register your device!"
echo "Complete"
