#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# Ensure PATH is set for commands running inside this script
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

"$UTIL" -i gitui fish git rust cargo

distro="$("$UTIL" -d)"
if [[ "$distro" == "fedora" ]]; then
    # the fedora build is currently broken, install via the official script instead
    curl -fsSL https://opencode.ai/install | bash
else
    "$UTIL" -i opencode
fi

# Configure fish shell
mkdir -p ~/.config/fish
tee ~/.config/fish/config.fish > /dev/null << 'EOL'
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Add user bin directories to PATH (Fish modern syntax)
fish_add_path ~/.local/bin ~/.opencode/bin

# yazi exit in current dir
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

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
# stop any running instances first so the freshly built binaries get used
systemctl --user stop grit.service krust.service 2>/dev/null || true
"$UTIL" -b https://github.com/bit-shift-io/krust.git krust
"$UTIL" -b https://github.com/bit-shift-io/grit.git grit

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

# Create and enable grit systemd user service
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
systemctl --user enable --now krust.service grit.service
loginctl enable-linger "$USER"

echo "Complete"
