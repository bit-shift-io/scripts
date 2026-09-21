#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

SHELL_VERSION="$(gnome-shell --version 2>/dev/null | awk '{print $NF}')"
if [[ -z "${SHELL_VERSION}" ]]; then
    echo "error: gnome-shell not found" >&2
    exit 1
fi
MAJOR="${SHELL_VERSION%%.*}"
echo "GNOME Shell ${SHELL_VERSION} (Major: ${MAJOR})"

# install software
echo -e '\n\nInstalling packages...'
"$UTIL" -i gnome-extensions-app breeze-icon-theme

# Reset shell settings so script applies fresh
dconf reset -f /org/gnome/shell/

# Safe array append for gsettings string-lists (e.g. ['ext1', 'ext2'])
gsettings_list_add() {
    local schema="$1" key="$2" value="$3"
    local current
    current="$(gsettings get "${schema}" "${key}")"

    if [[ "${current}" == "@as []" ]] || [[ "${current}" == "[]" ]]; then
        gsettings set "${schema}" "${key}" "['${value}']"
        return 0
    fi

    # Check if value exists in array
    if grep -q "'${value}'" <<< "${current}"; then
        return 0
    fi

    # Strip closing bracket, append, close bracket
    local updated="${current%\]}, '${value}']"
    gsettings set "${schema}" "${key}" "${updated}"
}

gset() {
    local schema="$1" key="$2" value="$3"
    if ! gsettings list-schemas | grep -qx "${schema}"; then
        echo "  skip ${schema}.${key}: schema not found"
        return 0
    fi
    if ! gsettings list-keys "${schema}" | grep -qx "${key}"; then
        echo "  skip ${schema}.${key}: key not found"
        return 0
    fi
    gsettings set "${schema}" "${key}" "${value}"
}

install_extension() {
    local uuid="$1"

    local current_status
    current_status="$(gnome-extensions info "${uuid}" 2>/dev/null || true)"
    if grep -q "Enabled: Yes" <<< "${current_status}" \
        && ! grep -q "State: ERROR" <<< "${current_status}"; then
        echo "  skip ${uuid}: already enabled"
        return 0
    fi

    echo "  installing ${uuid}..."

    # Attempt native DBus install prompt first
    if command -v busctl >/dev/null 2>&1 \
        && busctl --user call org.gnome.Shell /org/gnome/Shell \
            org.gnome.Shell.Extensions InstallRemoteExtension s "${uuid}" >/dev/null 2>&1; then
        echo "  ok ${uuid}"
        return 0
    fi

    # Fallback zip installation via GNOME extensions API
    local info url zip
    info="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${uuid}" 2>/dev/null || true)"
    url="$(grep -o '"download_url": "[^"]*"' <<< "${info}" | head -n1 | cut -d'"' -f4)"

    if [[ -n "${url}" ]]; then
        zip="/tmp/${uuid//\//_}.shell-extension.zip"
        curl -fsSL "https://extensions.gnome.org${url}" -o "${zip}"
        gnome-extensions install --force "${zip}"
        rm -f "${zip}"
        gsettings_list_add org.gnome.shell enabled-extensions "${uuid}"
        echo "  ok ${uuid} (zip fallback)"
    else
        echo "  warning: could not retrieve download URL for ${uuid}"
    fi
}

# Install requested extensions
install_extension "screentospace@dilzhan.dev"
install_extension "dash-to-dock@micxgx.gmail.com"
install_extension "caffeine@patapon.info"
install_extension "places-menu@gnome-shell-extensions.gcampax.github.com"
install_extension "blur-my-shell@aunetx"
install_extension "hidetopbar@mathieu.bidon.ca"
install_extension "touchup@mityax"
install_extension "ddterm@amezin.github.com"

# Disable unwanted extensions
if gnome-extensions info "background-logo@fedorahosted.org" > /dev/null 2>&1; then
    echo "  disabling background-logo@fedorahosted.org..."
    gnome-extensions disable "background-logo@fedorahosted.org" || true
fi

# Compile and include local extension schemas alongside system schemas
SCHEMA_DIRS=""
for d in ~/.local/share/gnome-shell/extensions/*/schemas; do
    if [[ -d "${d}" ]]; then
        glib-compile-schemas "${d}" 2>/dev/null || true
        SCHEMA_DIRS="${SCHEMA_DIRS}:${d}"
    fi
done
export GSETTINGS_SCHEMA_DIR="/usr/share/glib-2.0/schemas${SCHEMA_DIRS}"

# Extension preferences
gset org.gnome.shell.extensions.hidetopbar mouse-sensitive true
gset org.gnome.shell.extensions.ddterm ddterm-toggle-hotkey "['<Control>slash']"

# Core preferences
gset org.gnome.desktop.a11y.applications screen-keyboard-enabled false
gset org.gnome.mutter auto-maximize true
gset org.gnome.desktop.interface clock-format "'12h'"
gset org.gnome.desktop.interface color-scheme "'prefer-dark'"
gset org.gnome.desktop.wm.preferences button-layout "':minimize,maximize,close'"


# Fixed GVariant formatting for icon-theme
gset org.gnome.desktop.interface icon-theme "'breeze-dark'"

# Sort folders first (GTK file choosers)
gset org.gtk.Settings.FileChooser sort-directories-first true
gset org.gtk.gtk4.Settings.FileChooser sort-directories-first true

# disable notifications
gset org.gnome.desktop.notifications show-banners false

# Peripherals & Power
gset org.gnome.desktop.peripherals.touchpad natural-scroll true
gset org.gnome.desktop.peripherals.mouse natural-scroll true
gset org.gnome.settings-daemon.plugins.color night-light-enabled true
gset org.gnome.settings-daemon.plugins.color night-light-temperature 3700
gset org.gnome.settings-daemon.plugins.power ambient-enabled false
gset org.gnome.desktop.privacy disable-clipboard-authorization true
gset org.gnome.desktop.interface show-battery-percentage true

# disable brightness sensor service
sudo systemctl mask iio-sensor-proxy.service
sudo systemctl stop iio-sensor-proxy.service

# Hostname setup (safely handled for non-interactive shells)
CURRENT_HOSTNAME="$(hostnamectl --static 2>/dev/null || echo "${HOSTNAME:-localhost}")"
if [[ -t 0 ]]; then
    read -r -p "Set hostname [default: ${CURRENT_HOSTNAME}]: " target_hostname
    target_hostname="${target_hostname:-${CURRENT_HOSTNAME}}"
    if [[ "${target_hostname}" != "${CURRENT_HOSTNAME}" ]]; then
        sudo hostnamectl set-hostname --static --pretty "${target_hostname}"
        echo "  hostname updated to: ${target_hostname}"
    fi
fi


#
# START config gnome qt apps
#

# 1. Environment.d for systemd graphical session inheritance
ENV_DIR="${HOME}/.config/environment.d"
mkdir -p "$ENV_DIR"
cat << 'EOF' > "${ENV_DIR}/qt-theme.conf"
QT_QPA_PLATFORMTHEME=qt6ct
QT_AUTO_SCREEN_SCALE_FACTOR=1
QT_ENABLE_HIGHDPI_SCALING=1
EOF

# 2. Add fish snippet
FISH_CONF_DIR="${HOME}/.config/fish/conf.d"
if [ -d "$FISH_CONF_DIR" ] || command -v fish &>/dev/null; then
    mkdir -p "$FISH_CONF_DIR"
    cat << 'EOF' > "${FISH_CONF_DIR}/qt-theme.fish"
set -gx QT_QPA_PLATFORMTHEME qt6ct
set -gx QT_AUTO_SCREEN_SCALE_FACTOR 1
set -gx QT_ENABLE_HIGHDPI_SCALING 1
EOF
fi

# 3. Configure qt5ct AND qt6ct INI files (Breeze, Breeze Dark colors, GTK3 dialogs)
python3 - << 'EOF'
import configparser, os, glob

def apply_qt_config(config_dir_name):
    path = os.path.expanduser(f'~/.config/{config_dir_name}/{config_dir_name}.conf')
    os.makedirs(os.path.dirname(path), exist_ok=True)

    config = configparser.ConfigParser()
    config.read(path)

    for sec in ['Appearance', 'Fonts', 'Interface']:
        if not config.has_section(sec):
            config.add_section(sec)

    prefix = '/usr/share'
    breeze_colors = (
        glob.glob(f'{prefix}/{config_dir_name}/colors/BreezeDark.conf') +
        glob.glob(f'{prefix}/{config_dir_name}/colors/breezedark.conf')
    )
    color_scheme = breeze_colors[0] if breeze_colors else ''

    config.set('Appearance', 'style', 'Breeze')
    if color_scheme:
        config.set('Appearance', 'color_scheme_path', color_scheme)
    config.set('Appearance', 'standard_dialogs', 'gtk3')
    config.set('Appearance', 'icon_theme', 'breeze-dark')
    config.set('Fonts', 'general', 'Cantarell,10,-1,5,50,0,0,0,0,0')

    with open(path, 'w') as f:
        config.write(f)

apply_qt_config('qt5ct')
apply_qt_config('qt6ct')
EOF

# 4. Remove any stale local wrapper if it exists, and purge bad Scribus geometry config once
rm -f "${HOME}/.local/bin/scribus"
hash -r 2>/dev/null || true

SCRIBUS_CFG="${HOME}/.config/scribus"
if [ -d "$SCRIBUS_CFG" ]; then
    mv "$SCRIBUS_CFG" "${HOME}/.config/scribus.bak.$(date +%s)"
fi

# 5. Fix desktop launcher Exec path if pointing to a non-existent or wrapped binary
LOCAL_APPS="${HOME}/.local/share/applications"
mkdir -p "$LOCAL_APPS"
if [ -f /usr/share/applications/scribus.desktop ]; then
    sed 's|^Exec=.*|Exec=/usr/bin/scribus %f|' /usr/share/applications/scribus.desktop > "${LOCAL_APPS}/scribus.desktop"
    update-desktop-database "$LOCAL_APPS" &>/dev/null || true
fi

systemctl --user daemon-reload
#
# END QT Config
#

echo "Complete"
