#!/bin/bash
set -euo pipefail

# COSMIC desktop settings (config files edited directly; cosmic-config unavailable):
#   panel/dock hide on window overlap, no reserved space, transparent panel
#   screen off after 5 min idle, never suspend on AC
#   night light enabled

COSMIC_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/cosmic"

# write a value file, creating its app dir if needed
#   $1 = app id, $2 = key, $3 = value
cosmic_set() {
    local dir="$COSMIC_DIR/$1/v1"
    mkdir -p "$dir"
    printf '%s' "$3" > "$dir/$2"
}

# panel/dock: hide when windows overlap instead of reserving screen space
cosmic_set com.system76.CosmicPanel.Panel autohide 'OnOverlap'
cosmic_set com.system76.CosmicPanel.Panel exclusive_zone 'false'
cosmic_set com.system76.CosmicPanel.Dock autohide 'OnOverlap'
cosmic_set com.system76.CosmicPanel.Dock exclusive_zone 'false'

# fully transparent panel
cosmic_set com.system76.CosmicPanel.Panel opacity '0.0'

# power/idle: display off after 5 min on battery or AC, never suspend on AC
cosmic_set com.system76.CosmicIdle screen_off_time 'Some(300000)'
cosmic_set com.system76.CosmicIdle suspend_on_ac_time 'None'

# night light
cosmic_set com.system76.CosmicComp night_light_enabled 'true'

# window management: no active-hint border, click-to-focus only
cosmic_set com.system76.CosmicComp active_hint 'false'
cosmic_set com.system76.CosmicComp focus_follows_cursor 'false'

# touchpad: natural scroll, two-finger scrolling, clickfinger, tap to click
# (input_touchpad is one serialized struct, so the whole file is written)
mkdir -p "$COSMIC_DIR/com.system76.CosmicComp/v1"
cat > "$COSMIC_DIR/com.system76.CosmicComp/v1/input_touchpad" <<'EOF'
(
    state: Enabled,
    click_method: Some(Clickfinger),
    scroll_config: Some((
        method: Some(TwoFinger),
        natural_scroll: Some(true),
        scroll_button: None,
        scroll_factor: None,
    )),
    tap_config: Some((
        enabled: true,
        button_map: Some(LeftRightMiddle),
        drag: true,
        drag_lock: false,
    )),
)
EOF

# systemd user environment generator: export WAYLAND_DISPLAY for user services
# (grit etc.) by auto-detecting the active wayland socket
GENERATOR_DIR=/usr/lib/systemd/user-environment-generators
sudo mkdir -p "$GENERATOR_DIR"
sudo tee "$GENERATOR_DIR/50-cosmic-wayland.sh" > /dev/null <<'EOF'
#!/bin/sh
# Automatically find and export active Wayland display for systemd user services
if [ -z "$WAYLAND_DISPLAY" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
    for sock in "$XDG_RUNTIME_DIR"/wayland-*; do
        if [ -S "$sock" ]; then
            echo "WAYLAND_DISPLAY=$(basename "$sock")"
            break
        fi
    done
fi
EOF
sudo chmod +x "$GENERATOR_DIR/50-cosmic-wayland.sh"

echo "Complete (restart the COSMIC session to apply)"
