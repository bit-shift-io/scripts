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

echo "Complete (restart the COSMIC session to apply)"
