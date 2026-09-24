#!/bin/sh

echo "Download latest..."
TAG=$(curl -s https://api.github.com/repos/ensky0/tildaz/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
ARCH=$(uname -m)

URL=$(curl -s "https://api.github.com/repos/ensky0/tildaz/releases/tags/$TAG" | grep "browser_download_url" | grep "\.rpm\"" | grep "$ARCH" | cut -d '"' -f 4)
echo "$URL"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -sL "$URL" -o "$TMP/tildaz.rpm"

echo "Install..."
sudo dnf install dejavu-sans-mono-fonts
sudo dnf install -y "$TMP/tildaz.rpm"



echo "Config..."
CONFIG_DIR="$HOME/.config/tildaz"
mkdir -p "$CONFIG_DIR"

cat << 'EOF' > "$CONFIG_DIR/config_0.toml"
hotkey         = "F12"
shell          = "/bin/bash"
auto_start     = true
hidden_start   = true

theme          = "Catppuccin Mocha"
max_scroll_lines = 10000

[window]
dock_position   = "top"
width_percent   = 90
height_percent  = 75.0
offset_percent  = 50.0
opacity_percent = 100.0

[font]
family          = "DejaVu Sans Mono"
glyph_fallback  = ["Noto Sans CJK KR", "Noto Color Emoji"]
size_point      = 15
cell_width_ratio  = 1.0
line_height_ratio = 1.1


[input]
macos_option_as_alt = "none"

[keys]
# Tabs
new_tab             = ["ctrl+shift+t"]
close_tab           = ["ctrl+shift+w"]
prev_tab            = ["ctrl+shift+[", "ctrl+pageup"]
next_tab            = ["ctrl+shift+]", "ctrl+pagedown"]
switch_tab1         = ["alt+1"]
switch_tab2         = ["alt+2"]
switch_tab3         = ["alt+3"]
switch_tab4         = ["alt+4"]
switch_tab5         = ["alt+5"]
switch_tab6         = ["alt+6"]
switch_tab7         = ["alt+7"]
switch_tab8         = ["alt+8"]
switch_tab9         = ["alt+9"]

# Panes
split_left          = ["ctrl+shift+left"]
split_right         = ["ctrl+shift+right"]
split_up            = ["ctrl+shift+up"]
split_down          = ["ctrl+shift+down"]
focus_pane_left     = ["alt+left"]
focus_pane_right    = ["alt+right"]
focus_pane_up       = ["alt+up"]
focus_pane_down     = ["alt+down"]
resize_pane_left    = ["shift+alt+left"]
resize_pane_right   = ["shift+alt+right"]
resize_pane_up      = ["shift+alt+up"]
resize_pane_down    = ["shift+alt+down"]
equalize_panes      = ["shift+alt+0"]
zoom_pane           = ["ctrl+shift+z"]
close_pane          = ["ctrl+shift+x"]

# Search
find                = ["ctrl+shift+f"]

# Clipboard
copy                = ["ctrl+shift+c"]
paste               = ["ctrl+shift+v"]

# Window
fullscreen          = ["alt+return"]
fullscreen_workarea = ["shift+alt+return"]
quit                = ["alt+f4"]

# Tools
reset_terminal      = ["ctrl+shift+r"]
show_about          = ["ctrl+shift+i"]
open_config         = ["ctrl+shift+p"]
open_log            = ["ctrl+shift+l"]
dump_perf           = ["ctrl+shift+f12"]
EOF

echo "Done!"
