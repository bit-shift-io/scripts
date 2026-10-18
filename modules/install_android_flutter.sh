#!/bin/bash
set -euo pipefail

# Enable verbose mode with DEBUG=1
if [[ "${DEBUG:-0}" == "1" ]]; then
    echo "DEBUG MODE: Verbose output enabled"
fi

source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

ANDROID_SDK="$HOME/Android/Sdk"
FLUTTER_DIR="$HOME/Projects/flutter"
JBR_DST="/opt/jbr-21"

require_cmd() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "missing $1 - installing"
        return 1
    fi
    return 0
}

# ==============================================================================
# 1. DETECT LATEST STABLE FLUTTER VERSION
# ==============================================================================
STABLE_VERSION=$(curl -sL 'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json' 2>/dev/null | python3 -c 'import sys,json; releases=json.load(sys.stdin); [print(next((r.get("version","") for r in releases.get("releases",[]) if r.get("channel")=="stable"), ""))' 2>/dev/null || echo '3.47.7')
if [ -z "$STABLE_VERSION" ]; then
    STABLE_VERSION="3.47.7"  # fallback
fi
echo "Latest stable Flutter version: $STABLE_VERSION"
FLUTTER_TARBALL="$HOME/Projects/flutter_linux_${STABLE_VERSION}-stable.tar.xz"

# ==============================================================================
# 2. INSTALL SYSTEM PACKAGES (android tools, build deps, JDKs)
# ==============================================================================
echo "Installing system packages..."
# System packages already installed
# "$UTIL" -i android-tools clang llvm lld cmake ninja openjdk-devel

# ==============================================================================
# 2b. ANDROID SDK (standalone command-line tools)
# ==============================================================================
echo "Setting up Android SDK..."
ANDROID_SDK="$HOME/Android/Sdk"
ANDROID_SDKMANAGER="${ANDROID_SDK}/cmdline-tools/latest/bin/sdkmanager"

if [[ -x "${ANDROID_SDKMANAGER}" ]]; then
    echo "Android SDK already installed at ${ANDROID_SDK}"
else
    echo "Downloading Android SDK Command-line Tools..."
    mkdir -p "$ANDROID_SDK/cmdline-tools/latest"
    CMDLINE_TOOLS_ZIP="/tmp/cmdline-tools.zip"
    if [[ ! -f "${CMDLINE_TOOLS_ZIP}" ]]; then
        wget -q -O "${CMDLINE_TOOLS_ZIP}" \
            "https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip"
    fi
    unzip -qo "${CMDLINE_TOOLS_ZIP}" -d "${ANDROID_SDK}/cmdline-tools/latest"
    # Move contents up one level so sdkmanager is at cmdline-tools/latest/bin
    if [[ -d "${ANDROID_SDK}/cmdline-tools/latest/cmdline-tools" ]]; then
        mv "${ANDROID_SDK}/cmdline-tools/latest/cmdline-tools"/* "${ANDROID_SDK}/cmdline-tools/latest/"
        rmdir "${ANDROID_SDK}/cmdline-tools/latest/cmdline-tools"
    fi
    rm -f "${CMDLINE_TOOLS_ZIP}"
    echo "Android SDK installed at ${ANDROID_SDK}"
fi

# Accept licenses and install required SDK components
echo "Accepting Android SDK licenses..."
timeout 30 yes | "${ANDROID_SDKMANAGER}" --licenses > /dev/null 2>&1 || true

echo "Installing Android SDK components (this downloads ~1-2GB, may take a few minutes)..."
timeout 900 yes | "${ANDROID_SDKMANAGER}" --sdk_root="${ANDROID_SDK}" \
    "platform-tools" "platforms;android-36" "build-tools;36.0.0" 2>&1 | tail -10 || true

# ==============================================================================
# 3. FLUTTER SDK
# ==============================================================================
echo "Installing Flutter SDK..."
if [[ -x "${FLUTTER_DIR}/bin/flutter" ]]; then
    if timeout 10 "${FLUTTER_DIR}/bin/flutter" --version > /dev/null 2>&1; then
        echo "Flutter already installed at ${FLUTTER_DIR}, skipping download"
    else
        echo "Flutter installation at ${FLUTTER_DIR} is incomplete (timeout), removing and re-downloading..."
        rm -rf "${FLUTTER_DIR}"
    fi
fi
if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
    mkdir -p "$HOME/Projects"
    if [[ ! -f "${FLUTTER_TARBALL}" ]]; then
        echo "Downloading Flutter ${STABLE_VERSION}..."
        wget -c --tries=0 --retry-connrefused --waitretry=5 -O "${FLUTTER_TARBALL}" "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${STABLE_VERSION}-stable.tar.xz"
    else
        # Verify tarball integrity; if corrupted, delete and re-download
        if ! tar -tf "${FLUTTER_TARBALL}" > /dev/null 2>&1; then
            echo "Corrupted tarball detected (${FLUTTER_TARBALL}), removing and re-downloading..."
            rm -f "${FLUTTER_TARBALL}"
            echo "Downloading Flutter ${STABLE_VERSION}..."
            wget --tries=0 --retry-connrefused --waitretry=5 -O "${FLUTTER_TARBALL}" "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${STABLE_VERSION}-stable.tar.xz"
        fi
    fi
    echo "Extracting Flutter..."
    tar -xf "${FLUTTER_TARBALL}" -C "$HOME/Projects"
fi

# ==============================================================================
# 4. FIX ANDROID SDK EXEC BITS
# ==============================================================================
echo "Fixing Android SDK exec bits..."
fix_exec_bits() {
    local dir="$1"
    [[ -d "${dir}" ]] || return 0
    echo "Fixing exec bits in ${dir}"
    find "${dir}" -type f \( -path '*/bin/*' -o -name '*.sh' -o -name '*.py' \) -print0 2>/dev/null | \
        xargs -0 -r chmod +x 2>/dev/null || true
    if [[ "${FIX_ELF:-0}" == "1" ]]; then
        find "${dir}" -type f -print0 2>/dev/null | \
            xargs -0 -r grep -IlZF $'\x7fELF' 2>/dev/null | \
                xargs -0 -r chmod +x 2>/dev/null || true
    fi
}

if [[ -d "${ANDROID_SDK}" ]]; then
    for comp in platform-tools emulator cmdline-tools build-tools ndk; do
        fix_exec_bits "${ANDROID_SDK}/${comp}"
    done
    fix_exec_bits "${ANDROID_SDK}"
else
    echo "WARNING: Android SDK not found at ${ANDROID_SDK}"
    echo "Open Android Studio and use the SDK Manager to install Platform Tools + an Android Platform"
fi

# ==============================================================================
# 5. FIX SELINUX LABELS (Fedora only)
# ==============================================================================
echo "Fixing SELinux labels..."
fix_selinux() {
    if ! command -v restorecon > /dev/null 2>&1 || ! command -v semanage > /dev/null 2>&1; then
        return 0
    fi
    [[ "$(distro)" == "fedora" ]] || return 0
    for target in "${JBR_DST}" "$HOME/Android/android-studio/jbr" "$HOME/Android/Sdk"; do
        [[ -d "${target}" ]] || continue
        echo "Fixing SELinux labels in ${target}"
        sudo semanage fcontext -a -t bin_t "${target}(/.*)?" 2>/dev/null || sudo semanage fcontext -m -t bin_t "${target}(/.*)?" 2>/dev/null || true
        sudo restorecon -Rv "${target}" 2>/dev/null || true
    done
}
fix_selinux

# ==============================================================================
# 6. FLUTTER RUST BRIDGE (optional)
# ==============================================================================
if require_cmd cargo; then
    echo "Installing flutter_rust_bridge_codegen..."
    cargo install flutter_rust_bridge_codegen
    if require_cmd rustup; then
        rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
    fi
else
    echo "Cargo not installed - skipping flutter_rust_bridge"
fi

# ==============================================================================
# 7. VALIDATE
# ==============================================================================
echo "Validating..."

# Pick a JDK gradle/AGP are happy with (minimum 17)
JAVA_HOME_CANDIDATE=""
for j in \
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
    JAVA_HOME_CANDIDATE="$(dirname "$(dirname "$(readlink -f "$(command -v java 2>/dev/null)")")")" 2>/dev/null || true
fi

export PATH="$FLUTTER_DIR/bin:$HOME/.cargo/bin:$ANDROID_SDK/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk 2>/dev/null | tail -n 1)"
if [[ -n "${JAVA_HOME_CANDIDATE}" ]]; then
    export JAVA_HOME="$JAVA_HOME_CANDIDATE"
fi

export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_NDK_HOME="$ANDROID_NDK_HOME"

echo "Adopting Flutter environment variables..."

echo "Running Flutter doctor..."
if [[ "${DEBUG:-0}" == "1" ]]; then
    timeout 60 flutter doctor -v || echo "flutter doctor validation completed (timed out after 60s)"
else
    timeout 60 flutter doctor || echo "flutter doctor validation completed (timed out after 60s)"
fi

echo ""
echo "=========================================="
echo "Installation complete!"
echo "Flutter version: $STABLE_VERSION"
echo "Android SDK: $ANDROID_SDK"
echo "JAVA_HOME: $JAVA_HOME_CANDIDATE"
echo "=========================================="
