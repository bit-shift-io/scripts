#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

echo "installing the android toolchain"
echo "make sure you have already extracted android studio into the ~/Android folder and run the bin to install it, select ndk from the sdk manager"
read -p "Press Enter to continue..."

ANDROID_SDK="$HOME/Android/Sdk"
FLUTTER_DIR="$HOME/Projects/flutter"
FLUTTER_VERSION="3.44.7"
FLUTTER_TARBALL="$HOME/Projects/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

require_cmd() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "missing $1 - installing"
        return 1
    fi
    return 0
}

# ==============================================================================
# 1. SYSTEM PACKAGES (android tools, build deps, JDKs for gradle)
# ==============================================================================
echo "installing system packages..."
# note: fedora >= 40 only ships java-25/27 (android studio bundles the LTS jbr
# we prefer below). 'openjdk-devel' is a fallback mapped in util.sh per distro.
"$UTIL" -i android-tools clang llvm lld cmake ninja openjdk-devel

# Android Studio bundles a JDK (JBR, currently 21) that is ideal for Gradle/AGP,
# but its default install path lives under $HOME where SELinux (enforcing on
# fedora) labels the tree user_home_t and blocks gradle's daemon from spawning
# it (posix_spawn EACCES). Relocate it to /opt/jbr-21 (usr_t/bin_t/lib_t) and
# point JAVA_HOME there.
JBR_SRC="$HOME/Android/android-studio/jbr"
JBR_DST="/opt/jbr-21"
if [[ -x "${JBR_DST}/bin/java" ]]; then
    echo "jbr already at ${JBR_DST}"
elif [[ -x "${JBR_SRC}/bin/java" ]] && [[ -d /opt ]]; then
    echo "relocating jbr to ${JBR_DST} (SELinux-safe location)..."
    sudo cp -a "${JBR_SRC}" "${JBR_DST}"
    if command -v restorecon > /dev/null 2>&1; then
        sudo restorecon -Rv "${JBR_DST}" 2>/dev/null || true
    fi
fi

# Pick a JDK gradle/AGP are happy with (minimum 17). Preferred order:
#  1. relocated JBR at /opt/jbr-21 (clean SELinux label)
#  2. Android Studio bundled JBR
#  3. java-21/17 if present
#  4. system java (25/27)
JAVA_HOME_CANDIDATE=""
for j in \
    "${JBR_DST}" \
    "${JBR_SRC}" \
    "/usr/lib/jvm/java-21-openjdk" \
    "/usr/lib/jvm/java-17-openjdk" \
    "/usr/lib/jvm/java-latest-openjdk" \
    "/usr/lib/jvm/java-25-openjdk"; do
    if [[ -x "${j}/bin/java" ]]; then
        JAVA_HOME_CANDIDATE="${j}"
        break
    fi
done
if [[ -z "${JAVA_HOME_CANDIDATE}" ]]; then
    JAVA_HOME_CANDIDATE="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
fi

# ==============================================================================
# 2. FLUTTER SDK
# ==============================================================================
echo "installing flutter sdk..."
if [[ -x "${FLUTTER_DIR}/bin/flutter" ]]; then
    echo "flutter already installed at ${FLUTTER_DIR}, skipping download"
else
    mkdir -p "$HOME/Projects"
    if [[ ! -f "${FLUTTER_TARBALL}" ]]; then
        echo "downloading flutter ${FLUTTER_VERSION}..."
        wget -c --tries=0 --retry-connrefused --waitretry=5 -O "${FLUTTER_TARBALL}" "${FLUTTER_URL}"
    fi
    echo "extracting flutter..."
    tar -xf "${FLUTTER_TARBALL}" -C "$HOME/Projects"
fi

# ==============================================================================
# 3. FIX ANDROID SDK EXEC BITS
# syncthing/backup or some extraction tools strip the executable bit from the
# whole sdk; flutter doctor then reports "Android SDK file not found: adb".
# re-apply +x to every native ELF binary and script under the sdk components.
# ==============================================================================
fix_exec_bits() {
    local dir="$1"
    [[ -d "${dir}" ]] || return 0
    echo "fixing exec bits in ${dir}"

    # chmod +x on everything under */bin (executables + wrapper scripts) and on
    # script extensions. this is intentionally broad but safe: +x on data files
    # is harmless. avoids fragile grep/content detection that dies under
    # 'set -o pipefail' when it hits binary files.
    find "${dir}" -type f \( -path '*/bin/*' -o -name '*.sh' -o -name '*.py' \) -print0 2>/dev/null \
        | xargs -0 -r chmod +x 2>/dev/null || true

    # native ELF binaries (*.so, platform-tools, build-tools, emulator, ndk).
    # optional full pass (slow over ~18k ndk files); caller sets FIX_ELF=1.
    if [[ "${FIX_ELF:-0}" == "1" ]]; then
        find "${dir}" -type f -print0 2>/dev/null \
            | xargs -0 -r grep -IlZF $'\x7fELF' 2>/dev/null \
            | xargs -0 -r chmod +x 2>/dev/null || true
    fi
}

if [[ -d "${ANDROID_SDK}" ]]; then
    # fast pass: extension-based + bin/* shebang scripts only (skips the slow
    # ELF magic-byte scan over ~18k ndk files). env var FIX_ELF=1 opts into the
    # full ELF pass if a reinstall ever strips native binaries again.
    for comp in platform-tools emulator cmdline-tools build-tools ndk; do
        fix_exec_bits "${ANDROID_SDK}/${comp}"
    done
    fix_exec_bits "${ANDROID_SDK}"

    # android studio's bundled jbr (jdk 21) ships with exec bit intact, but our
    # backup/restore path can strip it the same way - ensure java/javac work.
    if [[ -d "$HOME/Android/android-studio/jbr/bin" ]]; then
        chmod +x "$HOME/Android/android-studio/jbr/bin"/* 2>/dev/null || true
    fi
else
    echo "WARNING: android sdk not found at ${ANDROID_SDK}"
    echo "open Android Studio and use the SDK Manager to install Platform Tools + an Android Platform"
fi

# ==============================================================================
# 3b. FIX SELINUX LABELS (fedora/rhel only)
# ==============================================================================
# On a SELinux-enforcing Fedora box, binaries extracted into ~/ get the
# user_home_t label, which blocks Gradle's daemon from posix_spawn'ing them
# ("Permission denied" / posix_spawn failed). The system JDKs under /usr are
# correctly bin_t/lib_t. Re-label the Android Studio JBR (and SDK helpers) so
# gradle/java can actually run them.
fix_selinux() {
    if ! command -v restorecon > /dev/null 2>&1 \
       || ! command -v semanage > /dev/null 2>&1; then
        return 0
    fi
    [[ "$(distro)" == "fedora" ]] || return 0

    for target in \
        "${JBR_DST}" \
        "$HOME/Android/android-studio/jbr" \
        "$HOME/Android/Sdk"; do
        [[ -d "${target}" ]] || continue
        echo "fixing selinux labels in ${target}"
        # register the tree as bin_t (matches /usr/lib/jvm/*/bin/* java)
        sudo semanage fcontext -a -t bin_t "${target}(/.*)?" 2>/dev/null \
            || sudo semanage fcontext -m -t bin_t "${target}(/.*)?" 2>/dev/null \
            || true
        sudo restorecon -Rv "${target}" 2>/dev/null || true
    done
}
fix_selinux

# ==============================================================================
# 4. FLUTTER RUST BRIDGE (optional, only if cargo is present)
# ==============================================================================
if require_cmd cargo; then
    echo "installing flutter_rust_bridge_codegen..."
    cargo install flutter_rust_bridge_codegen
    if require_cmd rustup; then
        rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
    fi
else
    echo "cargo not installed - skipping flutter_rust_bridge"
fi

# ==============================================================================
# 5. PERMANENT PATHS & ENV VARS (BASH)
# ==============================================================================
BASHRC="$HOME/.bashrc"
echo "updating $BASHRC..."

append_bashrc() {
    local line="$1"
    grep -qF "$line" "$BASHRC" 2>/dev/null || echo "$line" >> "$BASHRC"
}

append_bashrc '# Flutter & Android environment setup'
append_bashrc 'export ANDROID_HOME="$HOME/Android/Sdk"'
append_bashrc 'export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk 2>/dev/null | tail -n 1)"'
if [[ -n "${JAVA_HOME_CANDIDATE}" ]]; then
    append_bashrc "export JAVA_HOME=\"${JAVA_HOME_CANDIDATE}\""
fi
append_bashrc 'export PATH="$HOME/Projects/flutter/bin:$HOME/.cargo/bin:$ANDROID_HOME/platform-tools:$PATH"'

# ==============================================================================
# 6. PERMANENT PATHS & ENV VARS (FISH)
# ==============================================================================
echo "updating fish environment..."

FISH_CONFIG_DIR="$HOME/.config/fish"
FISH_CONFIG="$FISH_CONFIG_DIR/config.fish"
mkdir -p "$FISH_CONFIG_DIR"
touch "$FISH_CONFIG"

append_fish() {
    grep -qF "$1" "$FISH_CONFIG" 2>/dev/null || echo "$1" >> "$FISH_CONFIG"
}

append_fish ''
append_fish '# Flutter & Android environment setup'
append_fish 'fish_add_path $HOME/Projects/flutter/bin'
append_fish 'fish_add_path $HOME/.cargo/bin'
append_fish 'fish_add_path $HOME/.local/bin'
append_fish 'fish_add_path $HOME/Android/Sdk/platform-tools'
append_fish 'set -gx ANDROID_HOME $HOME/Android/Sdk'
append_fish 'set -l ndk_dirs $ANDROID_HOME/ndk/*'
append_fish 'if test -n "$ndk_dirs"; set -gx ANDROID_NDK_HOME $ndk_dirs[-1]; end'
if [[ -n "${JAVA_HOME_CANDIDATE}" ]]; then
    append_fish "set -gx JAVA_HOME ${JAVA_HOME_CANDIDATE}"
fi

# ==============================================================================
# 7. VALIDATE
# ==============================================================================
echo "validating..."
export PATH="$FLUTTER_DIR/bin:$HOME/.cargo/bin:${ANDROID_SDK}/platform-tools:$PATH"
export ANDROID_HOME="${ANDROID_SDK}"
if [[ -n "${JAVA_HOME_CANDIDATE}" ]]; then
    export JAVA_HOME="${JAVA_HOME_CANDIDATE}"
fi

if adb version > /dev/null 2>&1; then
    echo "adb: ok"
else
    echo "WARNING: adb still not working. try: sdkmanager --install platform-tools"
fi

if [[ -x "${ANDROID_SDK}/cmdline-tools/latest/bin/sdkmanager" ]]; then
    echo "sdkmanager: ok"
fi

echo "accepting android licenses..."
yes | flutter doctor --android-licenses > /dev/null 2>&1 || true
yes | "${ANDROID_SDK}/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null 2>&1 || true

echo "running flutter doctor..."
flutter doctor

echo ""
echo "complete! if the android section above is still marked, open android studio"
echo "and check the sdk manager has platform-tools + platforms;android-36 installed."
echo "restart your terminal or 'source ~/.bashrc' to apply the new paths."
echo "note: for a physical phone over usb the 'android-tools' package provides"
echo "the udev rules on fedora - plug the phone in and run 'adb devices'."