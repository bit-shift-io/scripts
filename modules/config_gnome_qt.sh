#!/usr/bin/env bash
set -euo pipefail

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
echo "Applied Qt/GTK integration, cleaned wrapper recursion, purged bad Scribus state, and reset desktop entry."
