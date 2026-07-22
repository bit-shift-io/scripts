#!/bin/bash
set -e

echo "installing the android toolchain"
echo "make sure you have already extracted android studio into the ~/Android folder and run the bin to install it, select ndk from the sdk manager"
read -p "Press Enter to continue..."

# android & build tools
./util.sh -i android-tools clang llvm lld

# https://docs.flutter.dev/platform-integration/android/setup
# flutter sdk
mkdir -p $HOME/Projects/flutter
cd $HOME/Projects
wget -c --tries=0 --retry-connrefused --waitretry=5 https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.7-stable.tar.xz

echo "extracting flutter..."
tar -xf $HOME/Projects/flutter_linux_3.44.7-stable.tar.xz -C $HOME/Projects

# flutter rust bridge
cargo install flutter_rust_bridge_codegen
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

# paths
ANDROID_HOME=$HOME/Android/Sdk
ANDROID_NDK_HOME=$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk 2>/dev/null | tail -n 1)

# ==============================================================================
# 4. PERMANENT PATHS & ENV VARS (BASH)
# ==============================================================================
BASHRC="$HOME/.bashrc"

echo "Updating $BASHRC..."

# Function to safely append to bashrc if not already present
append_bashrc() {
    local line="$1"
    grep -qF "$line" "$BASHRC" 2>/dev/null || echo "$line" >> "$BASHRC"
}

append_bashrc '# Flutter & Android environment setup'
append_bashrc 'export ANDROID_HOME="$HOME/Android/Sdk"'
append_bashrc 'export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk 2>/dev/null | tail -n 1)"'
append_bashrc 'export PATH="$HOME/Projects/flutter/bin:$HOME/.cargo/bin:$ANDROID_HOME/platform-tools:$PATH"'

# ==============================================================================
# 5. PERMANENT PATHS & ENV VARS (FISH)
# ==============================================================================
echo "Updating Fish environment..."

FISH_CONFIG_DIR="$HOME/.config/fish"
FISH_CONFIG="$FISH_CONFIG_DIR/config.fish"

echo "Updating $FISH_CONFIG..."
mkdir -p "$FISH_CONFIG_DIR"
touch "$FISH_CONFIG"

append_fish() {
    grep -qF "$1" "$FISH_CONFIG" 2>/dev/null || echo "$1" >> "$FISH_CONFIG"
}

append_fish '# Flutter & Android environment setup'
append_fish 'fish_add_path $HOME/Projects/flutter/bin'
append_fish 'fish_add_path $HOME/.cargo/bin'
append_fish 'fish_add_path $HOME/Android/Sdk/platform-tools'
append_fish 'set -gx ANDROID_HOME $HOME/Android/Sdk'
append_fish 'set -gx ANDROID_NDK_HOME $ANDROID_HOME/ndk/(ls $ANDROID_HOME/ndk 2>/dev/null | tail -n 1)'

echo "Complete! Restart your terminal or source your config file to apply changes."
