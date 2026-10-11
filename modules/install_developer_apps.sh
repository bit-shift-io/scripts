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

# Clone, build, and install Rust apps from git into ~/.local/bin
# Process each service sequentially: stop, build, start
# Start order: folio, krust, then grit. Grit auto-spawns krust when :3000
# is down at boot, so it must start only after krust is confirmed serving —
# otherwise a stale krust binary gets orphaned on the port and the fresh
# krust.service crash-loops on "Address already in use" forever.

# Ensure systemd user directory exists
mkdir -p "$HOME/.config/systemd/user"

# Process folio first
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

# Process grit second
echo "=== Processing grit ==="
systemctl --user stop grit.service 2>/dev/null || true
"$UTIL" -b https://github.com/bit-shift-io/grit.git grit

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

# Grit is built here but started last (see below) so that it boots with
# krust already up and never auto-spawns a stale krust from PATH.

# Process krust next (slowest build due to WASM)
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

# Start grit only once krust is confirmed up.
systemctl --user daemon-reload
systemctl --user enable --now grit.service
loginctl enable-linger "$USER"

echo "Complete"
