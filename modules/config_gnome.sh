#!/bin/bash
set -euo pipefail

# GNOME extensions for an android-like touch UI:
#   dash-to-dock            -> centered bottom gesture bar / nav pill
#   blur-my-shell           -> material-you blurred backdrop

SHELL_VERSION="$(gnome-shell --version 2>/dev/null | awk '{print $NF}')"
if [[ -z "${SHELL_VERSION}" ]]; then
    echo "error: gnome-shell not found" >&2
    exit 1
fi
MAJOR="${SHELL_VERSION%%.*}"
echo "GNOME Shell ${SHELL_VERSION}"

# install an extension from extensions.gnome.org matching the shell version
install_extension() {
    local uuid="$1"
    local info url zip

    info="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${MAJOR}" 2>/dev/null || true)"
    if [[ -z "${info}" ]] || ! grep -q "\"${MAJOR}\": {\"pk\"" <<< "${info}"; then
        echo "  skip ${uuid}: no build for GNOME Shell ${MAJOR}"
        return 0
    fi

    url="$(grep -o '"download_url": "[^"]*"' <<< "${info}" | cut -d'"' -f4)"
    zip="/tmp/${uuid//\//_}.shell-extension.zip"
    echo "  install ${uuid}"
    curl -fsSL "https://extensions.gnome.org${url}" -o "${zip}"
    gnome-extensions install --force "${zip}"
    gnome-extensions enable "${uuid}"
    rm -f "${zip}"
}

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

# dash-to-dock as a bottom gesture bar / nav pill
gset org.gnome.shell.extensions.dash-to-dock dock-position "'BOTTOM'"
gset org.gnome.shell.extensions.dash-to-dock dock-fixed false
gset org.gnome.shell.extensions.dash-to-dock autohide true
gset org.gnome.shell.extensions.dash-to-dock intellihide true
gset org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false
gset org.gnome.shell.extensions.dash-to-dock extend-height false
gset org.gnome.shell.extensions.dash-to-dock dock-alignment "'CENTER'"
gset org.gnome.shell.extensions.dash-to-dock icon-size-fixed false
gset org.gnome.shell.extensions.dash-to-dock icon-size 32
gset org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gset org.gnome.shell.extensions.dash-to-dock custom-background-color true
gset org.gnome.shell.extensions.dash-to-dock background-color "'#000000'"
gset org.gnome.shell.extensions.dash-to-dock background-opacity 0.5
gset org.gnome.shell.extensions.dash-to-dock transparency-mode "'FIXED'"
gset org.gnome.shell.extensions.dash-to-dock show-trash false
gset org.gnome.shell.extensions.dash-to-dock show-mounts false

# blur-my-shell material-you backdrop
gset org.gnome.shell.extensions.blur-my-shell blur-enabled true
gset org.gnome.shell.extensions.blur-my-shell panel-blur true
gset org.gnome.shell.extensions.blur-my-shell dash-blur true
gset org.gnome.shell.extensions.blur-my-shell overview-blur true
gset org.gnome.shell.extensions.blur-my-shell appfolder-blur true
gset org.gnome.shell.extensions.blur-my-shell corner-radius 12
gset org.gnome.shell.extensions.blur-my-shell sigma 18

# stock on-screen keyboard for touch input
gset org.gnome.desktop.a11y.applications screen-keyboard-enabled true

echo "Complete"