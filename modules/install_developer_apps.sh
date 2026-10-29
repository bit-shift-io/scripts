#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

# Ensure PATH is set for commands running inside this script
#export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

"$UTIL" -i fish git rust cargo

# if this breaks, use the method below
"$UTIL" -i opencode

#distro="$("$UTIL" -d)"
#if [[ "$distro" == "fedora" ]]; then
    # the fedora build is currently broken, install via the official script instead
#    curl -fsSL https://opencode.ai/install | bash
#else
#    "$UTIL" -i opencode
#fi

# set fish default
#chsh -s "$(command -v fish)" # dont use this, it breaks all scripts!
chsh -s "$(command -v bash)"

# Configure fish shell
mkdir -p ~/.config/fish
tee ~/.config/fish/config.fish > /dev/null << EOL
# Add user bin directories to PATH (Fish modern syntax)
fish_add_path ~/.local/bin ~/.opencode/bin

# disable greeting
set fish_greeting ""

# force Qt apps to use Wayland
set -gx QT_QPA_PLATFORM wayland
EOL


# Configure bashrc auto-switch to fish
BASHRC="$HOME/.bashrc"
if grep -q "fish" "$BASHRC"; then
    echo "Fish shell command is already present in $BASHRC. Skipping append."
else
    echo "Appending fish execution to $BASHRC..."
    cat <<'EOT' >> "$BASHRC"

# Switch to fish shell if interactive
if [[ $- == *i* ]]; then
    exec fish
fi
EOT
    echo "Bashrc configuration updated."
fi

# Ask if user wants to install developer apps (folio, grit, krust) at the start
read -rp "Install developer apps (folio, grit, krust)? [y/N] " install_apps
install_apps="${install_apps:-n}"
if [[ "$install_apps" != "y" && "$install_apps" != "Y" ]]; then
    echo "Skipping developer app installation."
else
    echo "Installing developer apps..."

    # Ensure systemd user directory exists
    mkdir -p "$HOME/.config/systemd/user"

    # Install folio first
    echo "=== Processing folio ==="
    systemctl --user stop folio.service 2>/dev/null || true
    "$UTIL" -b https://github.com/bit-shift-io/folio.git folio

    tee "$HOME/.config/systemd/user/folio.service" > /dev/null << EOL
[Unit]
Description=folio Service
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/bin/folio
WorkingDirectory=%h
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOL

    systemctl --user daemon-reload
    systemctl --user enable --now folio.service

    # Install krust next (slowest build due to WASM)
    echo "=== Processing krust ==="
    systemctl --user stop krust.service 2>/dev/null || true
    # Reap any stray krust (e.g. one grit auto-spawned in the past) and wait
    # until the port is actually free, or the rebuilt service can't bind it.
    pkill -x krust 2>/dev/null || true
    for _ in $(seq 1 10); do
        curl -s --max-time 1 "http://127.0.0.1:3000/" >/dev/null 2>&1 || break
        sleep 1
    done
    "$UTIL" -b https://github.com/bit-shift-io/krust.git krust

    # Create and enable krust systemd user service
    mkdir -p "$HOME/.config/systemd/user"

    tee "$HOME/.config/systemd/user/krust.service" > /dev/null << EOL
[Unit]
Description=krust Web Terminal Service
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/bin/krust
WorkingDirectory=%h
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOL

    systemctl --user daemon-reload
    systemctl --user enable --now krust.service

    # Fail loudly if krust never comes up, instead of printing "Complete" over
    # a service that is crash-looping on a port an orphan still holds.
    krust_up=0
    for _ in $(seq 1 15); do
        if curl -s --max-time 1 "http://127.0.0.1:3000/" >/dev/null 2>&1; then
            krust_up=1
            break
        fi
        sleep 1
    done
    if [[ "$krust_up" -ne 1 ]]; then
        echo "ERROR: krust.service is not serving on :3000 after install" >&2
        exit 1
    fi

    # Build and install grit last: it serves the web UI on :5000 and its web
    # assets are embedded in the binary, so it can only start once krust is
    # confirmed up. Same stop/pkill/port-wait dance as krust above, or the
    # rebuilt service can't bind :5000.
    echo "=== Processing grit ==="
    systemctl --user stop grit.service 2>/dev/null || true
    pkill -x grit 2>/dev/null || true
    for _ in $(seq 1 10); do
        curl -s --max-time 1 "http://127.0.0.1:5000/" >/dev/null 2>&1 || break
        sleep 1
    done
    "$UTIL" -b https://github.com/bit-shift-io/grit.git grit

    # Written here too so a fresh machine provisions without a hand-made unit
    # file. Wired to graphical-session.target (the desktop UI expects it) with
    # Restart=on-failure, matching the existing grit setup.
    tee "$HOME/.config/systemd/user/grit.service" > /dev/null << EOL
[Unit]
Description=Grit Git client daemon
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=%h/.local/bin/grit --headless --port 5000
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOL

    systemctl --user daemon-reload
    systemctl --user enable --now grit.service
    loginctl enable-linger "$USER"

    # Fail loudly if grit never comes up, instead of printing "Complete" over
    # a service that is crash-looping.
    grit_up=0
    for _ in $(seq 1 15); do
        if curl -s --max-time 1 "http://127.0.0.1:5000/" >/dev/null 2>&1; then
            grit_up=1
            break
        fi
        sleep 1
    done
    if [[ "$grit_up" -ne 1 ]]; then
        echo "ERROR: grit.service is not serving on :5000 after install" >&2
        exit 1
    fi
fi

# === OpenCode configuration ===
OPENCODE_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_DIR/plugins"
mkdir -p "$OPENCODE_DIR"

# Copy network watchdog plugin to global plugins directory
cp "$SCRIPT_DIR/services/network-watchdog.js" "$OPENCODE_DIR/plugins/network-watchdog.js"

# Overwrite the config file with the desired settings
cat > "$OPENCODE_DIR/opencode.jsonc" << 'ENDEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "options": {
      "timeout": 300000,
      "chunkTimeout": 10000,
      "keepAlive": true,
      "keepAliveMsecs": 5000
    }
  },
  "compaction": {
    "auto": true,
    "threshold": 0.65
  },
  "lsp": true,
  "permission": {
    "write": "allow",
    "apply_patch": "allow",
    "todowrite": "allow",
    "skill": {
      "*": "allow"
    },
    "read": {
      "*": "allow",
      "data": "allow",
      "data/**": "allow",
      "~/.cargo": "allow",
      "~/.cargo/**": "allow",
      "/tmp": "allow",
      "/tmp/**": "allow",
      "/var/tmp": "allow",
      "/var/tmp/**": "allow"
    },
    "edit": {
      "*": "allow",
      "data": "allow",
      "data/**": "allow",
      "~/.cargo": "allow",
      "~/.cargo/**": "allow",
      "/tmp": "allow",
      "/tmp/**": "allow",
      "/var/tmp": "allow",
      "/var/tmp/**": "allow"
    },
    "bash": {
      "*": "allow",
      "*data*": "allow",
      "git commit*": "deny",
      "git push*": "deny"
    }
  },
  "plugin": [
    "opencode-auto-continue@https://github.com/developing-today/opencode-auto-continue/archive/refs/tags/latest.tar.gz",
    "./plugins/network-watchdog.js",
    "superpowers@git+https://github.com/obra/superpowers.git"
  ]
}
ENDEOF

# Write auto-continue config to global config directory
cat > "$OPENCODE_DIR/opencode-auto-continue.jsonc" << 'ENDEOF2'
{
  "enabled": true,
  // Wait 10 seconds after an error state before reconnecting
  "delayMs": 10000,
  // 0 enables infinite consecutive retries
  "maxConsecutive": 0,
  // Minimum delay between auto-continue attempts
  "throttleMs": 5000
}
ENDEOF2

echo "OpenCode configuration complete."

# === OpenCode startup service ===
# V2 service mode registers this foreground server for normal TUI discovery,
# so systemd and terminal clients share one server rather than competing ones.
OPENCODE_BIN="$(command -v opencode)"
mkdir -p "$HOME/.config/systemd/user"

# Read and confirm before stopping anything. Blank preserves the current (or
# automatically generated) password; never store the secret in the unit file.
while true; do
    if ! IFS= read -rsp "OpenCode password (blank keeps current/generated password): " OPENCODE_PASSWORD_INPUT; then
        echo "ERROR: Could not read OpenCode password; service setup cancelled." >&2
        exit 1
    fi
    echo >&2
    [[ -z "$OPENCODE_PASSWORD_INPUT" ]] && break
    if ! IFS= read -rsp "Confirm OpenCode password: " OPENCODE_PASSWORD_CONFIRM; then
        echo "ERROR: Could not confirm OpenCode password; service setup cancelled." >&2
        exit 1
    fi
    echo >&2
    [[ "$OPENCODE_PASSWORD_INPUT" == "$OPENCODE_PASSWORD_CONFIRM" ]] && break
    unset OPENCODE_PASSWORD_INPUT OPENCODE_PASSWORD_CONFIRM
    echo "Passwords do not match. Please try again." >&2
done

# Stop supervision before changing settings (each service set stops the old
# background server). This also migrates an automatically started V2 daemon.
systemctl --user stop opencode.service 2>/dev/null || true
"$OPENCODE_BIN" service set hostname 0.0.0.0
"$OPENCODE_BIN" service set port 49374
"$OPENCODE_BIN" service unset disabled

if [[ -n "$OPENCODE_PASSWORD_INPUT" ]]; then
    "$OPENCODE_BIN" service set password "$OPENCODE_PASSWORD_INPUT" > /dev/null
fi
unset OPENCODE_PASSWORD_INPUT OPENCODE_PASSWORD_CONFIRM

# Escape systemd specifiers in the resolved executable path.
OPENCODE_EXEC="${OPENCODE_BIN//%/%%}"
cat > "$HOME/.config/systemd/user/opencode.service" << EOL
[Unit]
Description=OpenCode shared API and web service
After=network.target

[Service]
Type=simple
ExecStart="$OPENCODE_EXEC" serve --service
WorkingDirectory=%h
Environment="PATH=%h/.local/bin:%h/.opencode/bin:%h/.cargo/bin:/usr/local/bin:/usr/bin:/bin"
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOL

systemctl --user daemon-reload
loginctl enable-linger "$USER"
systemctl --user enable --now opencode.service

echo "OpenCode web UI: http://<LAN-IP>:49374 (allow TCP 49374 on your LAN firewall if needed)."
echo "Authentication username: opencode. The configured password is stored by OpenCode, not in the unit file."
echo "If your browser requires pairing, run: opencode pair --url http://<LAN-IP>:49374"
echo "Open the generated one-time link on that device. Do not expose this port to the internet."
echo "Complete"
