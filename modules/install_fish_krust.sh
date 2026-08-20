#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
set -e

# Repository URL for krust (update this to your repository location)
KRUST_REPO="https://github.com/bit-shift-io/krust.git"

# Install dependencies (fish, git, cargo/rust)
"$UTIL" -i fish git rust cargo

# Configure fish shell
tee ~/.config/fish/config.fish > /dev/null << 'EOL'
if status is-interactive
   # Commands to run in interactive sessions can go here
end

# Created by pipx on 2025-05-23 00:57:46
set PATH $PATH $HOME/.local/bin

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

# Clone, build, and install krust
echo "Building and installing krust..."
BUILD_DIR=$(mktemp -d)

git clone "$KRUST_REPO" "$BUILD_DIR"
cargo build --release --manifest-path "$BUILD_DIR/Cargo.toml"

mkdir -p "$HOME/.local/bin"
cp "$BUILD_DIR/target/release/krust" "$HOME/.local/bin/krust"
rm -rf "$BUILD_DIR"

echo "krust binary installed to $HOME/.local/bin/krust"

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
loginctl enable-linger "$USER"

echo "Complete"
