#!/bin/bash
set -euo pipefail

# GNOME extensions for an android-like touch UI:
#   dash-to-dock            -> centered bottom gesture bar / nav pill
#   blur-my-shell           -> material-you blurred backdrop
#   just-perfection         -> clean up / tune the shell (panel, OSD, ...)
#   touchup                 -> android-like gestures / nav bar / osk

SHELL_VERSION="$(gnome-shell --version 2>/dev/null | awk '{print $NF}')"
if [[ -z "${SHELL_VERSION}" ]]; then
    echo "error: gnome-shell not found" >&2
    exit 1
fi
MAJOR="${SHELL_VERSION%%.*}"
echo "GNOME Shell ${SHELL_VERSION}"

# install an extension from extensions.gnome.org matching the shell version
#   primary:   ask the running shell to download+install+enable it
#              (opens a confirmation dialog; the user must click "Install")
#   fallback:  manual zip install for headless/older setups
install_extension() {
    local uuid="$1"
    local info

    # skip if it is already installed, enabled and not erroring
    local current_status
    current_status="$(gnome-extensions info "${uuid}" 2>/dev/null || true)"
    if grep -q "Enabled: Yes" <<< "${current_status}" \
        && ! grep -q "State: ERROR" <<< "${current_status}"; then
        echo "  skip ${uuid}: already enabled"
        return 0
    fi

    info="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${MAJOR}" 2>/dev/null || true)"
    if [[ -z "${info}" ]] || ! grep -q "\"${MAJOR}\": {\"pk\"" <<< "${info}"; then
        echo "  skip ${uuid}: no build for GNOME Shell ${MAJOR}"
        return 0
    fi

    echo "  install ${uuid}"
    # let the shell download, install and enable it (user confirms the dialog)
    if command -v busctl >/dev/null 2>&1 \
        && busctl --user call org.gnome.Shell /org/gnome/Shell \
            org.gnome.Shell.Extensions InstallRemoteExtension s "${uuid}" >/dev/null 2>&1; then
        echo "  ok ${uuid}"
        return 0
    fi

    # fallback: manual zip install
    local url zip
    url="$(grep -o '"download_url": "[^"]*"' <<< "${info}" | cut -d'"' -f4)"
    zip="/tmp/${uuid//\//_}.shell-extension.zip"
    curl -fsSL "https://extensions.gnome.org${url}" -o "${zip}"
    gnome-extensions install --force "${zip}"
    rm -f "${zip}"

    # the shell may not have rescanned yet, so enabling can fail with
    # 'Extension "..." does not exist'; persist it for the next session then
    if ! gnome-extensions enable "${uuid}" >/dev/null 2>&1; then
        gsettings_list_add org.gnome.shell enabled-extensions "${uuid}"
        echo "  note: ${uuid} installed but will activate after logging out/in"
    fi
}

# add a string to a gsettings string-list (org.gnome.shell.enabled-extensions)
gsettings_list_add() {
    local schema="$1" key="$2" value="$3"
    local current inner
    current="$(gsettings get "${schema}" "${key}")"
    if [[ "${current}" == "@as []" ]]; then
        gsettings set "${schema}" "${key}" "['${value}']"
        return 0
    fi
    inner="${current#\[}"
    inner="${inner%\]}"
    if [[ ",${inner// /}," == *",'${value}',"* ]]; then
        return 0
    fi
    gsettings set "${schema}" "${key}" "[${inner}', '${value}']"
}

# add every installed extension's schema dir so `gsettings` can see them
SCHEMA_DIRS=""
for d in ~/.local/share/gnome-shell/extensions/*/schemas; do
    [[ -d "${d}" ]] && SCHEMA_DIRS="${SCHEMA_DIRS}:${d}"
done
export GSETTINGS_SCHEMA_DIR="${GSETTINGS_SCHEMA_DIR:-}${SCHEMA_DIRS}"

# set a gsettings value only if the schema/key exist
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

install_extension "dash-to-dock@micxgx.gmail.com"
install_extension "blur-my-shell@aunetx"
install_extension "just-perfection-desktop@just-perfection"
install_extension "touchup@mityax"
install_extension "screentospace@dilzhan.dev"

# dash-to-dock as a bottom gesture bar / nav pill
gset org.gnome.shell.extensions.dash-to-dock dock-position "'BOTTOM'"
gset org.gnome.shell.extensions.dash-to-dock dock-fixed false
gset org.gnome.shell.extensions.dash-to-dock autohide true
gset org.gnome.shell.extensions.dash-to-dock intellihide true
gset org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false
gset org.gnome.shell.extensions.dash-to-dock extend-height false
gset org.gnome.shell.extensions.dash-to-dock icon-size-fixed false
gset org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
gset org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gset org.gnome.shell.extensions.dash-to-dock custom-background-color true
gset org.gnome.shell.extensions.dash-to-dock background-color "'#000000'"
gset org.gnome.shell.extensions.dash-to-dock background-opacity 0.5
gset org.gnome.shell.extensions.dash-to-dock transparency-mode "'FIXED'"
gset org.gnome.shell.extensions.dash-to-dock show-trash false
gset org.gnome.shell.extensions.dash-to-dock show-mounts false

# blur-my-shell material-you backdrop
#   GNOME 50 schema is split into per-target sub-schemas (panel, dash-to-dock,
#   overview, appfolder, ...); blur is enabled by default, only tune it here
gset org.gnome.shell.extensions.blur-my-shell sigma 18
gset org.gnome.shell.extensions.blur-my-shell.panel blur true
gset org.gnome.shell.extensions.blur-my-shell.panel customize true
gset org.gnome.shell.extensions.blur-my-shell.panel corner-radius 12
gset org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
gset org.gnome.shell.extensions.blur-my-shell.dash-to-dock customize true
gset org.gnome.shell.extensions.blur-my-shell.dash-to-dock corner-radius 12
gset org.gnome.shell.extensions.blur-my-shell.overview blur true
gset org.gnome.shell.extensions.blur-my-shell.appfolder blur true

# just-perfection: touch-friendly tweaks
gset org.gnome.shell.extensions.just-perfection panel-in-overview true
gset org.gnome.shell.extensions.just-perfection panel-size 36
gset org.gnome.shell.extensions.just-perfection workspace-wrap-around true

# stock on-screen keyboard for touch input
gset org.gnome.desktop.a11y.applications screen-keyboard-enabled false

# auto-maximize new windows (touch friendly)
gset org.gnome.mutter auto-maximize true

# 12-hour clock
gset org.gnome.desktop.interface clock-format "'12h'"

# dark color scheme
gset org.gnome.desktop.interface color-scheme "'prefer-dark'"

# natural (non-inverted) touchpad scrolling
gset org.gnome.desktop.peripherals.touchpad natural-scroll false

# night light
gset org.gnome.settings-daemon.plugins.color night-light-enabled true

# disable clipboard authorization prompt
gset org.gnome.desktop.privacy disable-clipboard-authorization true

echo "Complete"