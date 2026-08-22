#!/bin/bash

# install helper works with:
# arch:   pacman, yay, paru
# debian: apt
# fedora: dnf
# suse:   zypper

# detect the distro family from /etc/os-release
function distro {
    local id
    id=$(. /etc/os-release 2>/dev/null && echo "${ID_LIKE:-$ID}" | tr '[:upper:]' '[:lower:]')
    case " ${id} " in
        *arch*)                      echo arch ;;
        *debian*|*ubuntu*)           echo debian ;;
        *fedora*|*rhel*|*centos*)    echo fedora ;;
        *suse*|*opensuse*)           echo suse ;;
        *)                           echo unknown ;;
    esac
}

# raw os-release ID (e.g. manjaro) for special cases
function os_id {
    . /etc/os-release 2>/dev/null && echo "${ID:-unknown}"
}

# pick the package manager for the current distro
function detect_install_util {
    local d
    d=$(distro)
    case "${d}" in
        arch)
            for u in paru yay pacman; do
                command -v "${u}" > /dev/null 2>&1 && { echo "${u}"; return; }
            done
            ;;
        debian)
            command -v apt > /dev/null 2>&1 && { echo apt; return; }
            ;;
        fedora)
            command -v dnf > /dev/null 2>&1 && { echo dnf; return; }
            ;;
        suse)
            command -v zypper > /dev/null 2>&1 && { echo zypper; return; }
            ;;
        *)
            for u in paru yay pacman apt dnf zypper; do
                command -v "${u}" > /dev/null 2>&1 && { echo "${u}"; return; }
            done
            ;;
    esac
}

# resolve a logical package name to the actual packages for this distro.
# recognised tokens:
#   aur:<pkg>            -> install via the AUR helper (arch only)
#   copr:<proj>:<pkg>    -> enable the COPR project then install (fedora only)
#   repofile:<url>:<pkg> -> add a repo from a .repo URL then install (fedora only)
#   skip:<name>          -> not available on this distro
function pkg {
    local d name
    d=$(distro)
    name="${1}"

    case "${d}:${name}" in
        arch:base-devel)                       echo "base-devel" ;;
        debian:base-devel)                     echo "build-essential" ;;
        fedora:base-devel)                     echo "@development-tools" ;;

        arch:vulkan-drivers)                   echo "vulkan-radeon lib32-vulkan-radeon vulkan-intel" ;;
        debian:vulkan-drivers)                 echo "mesa-vulkan-drivers" ;;
        fedora:vulkan-drivers)                 echo "mesa-vulkan-drivers" ;;

        arch:sshfs)                            echo "sshfs" ;;
        debian:sshfs)                          echo "sshfs" ;;
        fedora:sshfs)                          echo "fuse-sshfs" ;;

        arch:cups-pdf)                         echo "aur:cups-pdf" ;;
        debian:cups-pdf)                       echo "cups-pdf" ;;
        fedora:cups-pdf)                       echo "cups-pdf" ;;

        arch:adobe-source-han-sans-cn-fonts)   echo "adobe-source-han-sans-cn-fonts" ;;
        debian:adobe-source-han-sans-cn-fonts) echo "fonts-noto-cjk" ;;
        fedora:adobe-source-han-sans-cn-fonts) echo "adobe-source-han-sans-cn-fonts" ;;

        arch:adobe-source-han-serif-cn-fonts)  echo "adobe-source-han-serif-cn-fonts" ;;
        debian:adobe-source-han-serif-cn-fonts) echo "fonts-noto-cjk" ;;
        fedora:adobe-source-han-serif-cn-fonts) echo "adobe-source-han-serif-cn-fonts" ;;

        arch:fcitx5-gtk)                       echo "fcitx5-gtk" ;;
        debian:fcitx5-gtk)                     echo "fcitx5-frontend-gtk3" ;;
        fedora:fcitx5-gtk)                     echo "fcitx5-gtk" ;;

        arch:fcitx5-qt)                        echo "fcitx5-qt" ;;
        debian:fcitx5-qt)                      echo "fcitx5-frontend-qt5" ;;
        fedora:fcitx5-qt)                      echo "fcitx5-qt" ;;

        arch:yay)                              echo "aur:yay" ;;
        debian:yay)                            echo "skip:yay" ;;
        fedora:yay)                            echo "skip:yay" ;;

        arch:zed)                              echo "zed" ;;
        debian:zed)                            echo "skip:zed" ;;
        fedora:zed)                            echo "copr:pgdev/zed:zed" ;;

        arch:sourcegit)                        echo "aur:sourcegit-bin" ;;
        debian:sourcegit)                      echo "skip:sourcegit" ;;
        fedora:sourcegit)                      echo "repofile:https://codeberg.org/api/packages/yataro/rpm.repo:sourcegit" ;;

        arch:binder_linux-dkms)                echo "aur:binder_linux-dkms" ;;
        *:binder_linux-dkms)                   echo "skip:binder_linux-dkms" ;;

        arch:binder_linux-dkms-git)            echo "aur:binder_linux-dkms-git" ;;
        *:binder_linux-dkms-git)               echo "skip:binder_linux-dkms-git" ;;

        arch:brother-mfc-j4440dw)              echo "aur:brother-mfc-j4440dw" ;;
        *:brother-mfc-j4440dw)                 echo "skip:brother-mfc-j4440dw" ;;

        arch:coolercontrol-bin)                echo "aur:coolercontrol-bin" ;;
        *:coolercontrol-bin)                   echo "skip:coolercontrol-bin" ;;

        arch:noctalia-shell)                   echo "aur:noctalia-shell" ;;
        *:noctalia-shell)                      echo "skip:noctalia-shell" ;;

        arch:qt6-heic-image-plugin)            echo "aur:qt6-heic-image-plugin" ;;
        *:qt6-heic-image-plugin)               echo "skip:qt6-heic-image-plugin" ;;

        arch:radeon-profile-daemon-git)        echo "aur:radeon-profile-daemon-git" ;;
        *:radeon-profile-daemon-git)           echo "skip:radeon-profile-daemon-git" ;;

        arch:radeon-profile-git)               echo "aur:radeon-profile-git" ;;
        *:radeon-profile-git)                  echo "skip:radeon-profile-git" ;;

        arch:rtl88x2bu-dkms-git)               echo "aur:rtl88x2bu-dkms-git" ;;
        *:rtl88x2bu-dkms-git)                  echo "skip:rtl88x2bu-dkms-git" ;;

        arch:virtualbox-ext-oracle)            echo "aur:virtualbox-ext-oracle" ;;
        *:virtualbox-ext-oracle)               echo "skip:virtualbox-ext-oracle" ;;

        fedora:python3-dnf-plugin-local)       echo "python3-dnf-plugin-local" ;;
        *:python3-dnf-plugin-local)            echo "skip:python3-dnf-plugin-local" ;;

        fedora:lact)                           echo "copr:ilyaz/LACT:lact" ;;

        debian:python-dbus)                    echo "python3-dbus" ;;
        fedora:python-dbus)                    echo "python3-dbus" ;;

        debian:libcec)                         echo "libcec4" ;;

        fedora:retroarch-assets-ozone)         echo "retroarch-assets" ;;
        fedora:retroarch-assets-xmb)           echo "retroarch-assets" ;;

        arch:opencode)                         echo "opencode" ;;
        fedora:opencode)                       echo "copr:sureclaw/opencode:opencode" ;;
        *:opencode)                            echo "skip:opencode" ;;

        *:manjaro-asian-input-support-fcitx5)
            if [[ "$(os_id)" == "manjaro" ]]; then
                echo "manjaro-asian-input-support-fcitx5"
            else
                echo "skip:manjaro-asian-input-support-fcitx5"
            fi
            ;;

        *)                                     echo "${name}" ;;
    esac
}

# clone a git repo, build it with cargo --release and copy the binary
# into ~/.local/bin:  util.sh -b <repo_url> <binary_name>
function build_rust_app {
    local repo bin build_dir
    repo="${1}"
    bin="${2}"

    echo "Building and installing ${bin}..."
    build_dir=$(mktemp -d)

    git clone "${repo}" "${build_dir}"
    cargo build --release --manifest-path "${build_dir}/Cargo.toml"

    mkdir -p "${HOME}/.local/bin"
    cp "${build_dir}/target/release/${bin}" "${HOME}/.local/bin/${bin}"
    rm -rf "${build_dir}"

    echo "${bin} binary installed to ${HOME}/.local/bin/${bin}"
}

function main {
    type="${1}"
    shift

    if [[ "${type}" == "-d" ]]; then
        distro
        return
    fi

    if [[ "${type}" == "-b" ]]; then
        build_rust_app "$@"
        return
    fi

    install_util=$(detect_install_util)
    echo "distro: $(distro)"
    echo "found: ${install_util}"

    # resolve logical package names to distro specific ones
    local resolved=()
    for arg in "$@"; do
        read -ra pkgs <<< "$(pkg "${arg}")"
        resolved+=("${pkgs[@]}")
    done

    case ${type} in
        '-i') install "${install_util}" "${resolved[@]}" ;;

        '-r') remove "${install_util}" "${resolved[@]}" ;;

        *)    echo "unknown" ;;
    esac
}

function install {
    local bin="${1}"
    shift

    for item in "$@"; do
        case "${item}" in
            skip:*)
                echo "skip ${item#skip:}: not available on $(distro)"
                ;;
            aur:*)
                case "${bin}" in
                    'paru'|'yay')
                        ${bin} -S --noconfirm --needed "${item#aur:}"
                        ;;
                    *)
                        echo "skip ${item#aur:}: AUR package, needs paru/yay"
                        ;;
                esac
                ;;
            copr:*)
                if [[ "${bin}" == "dnf" ]]; then
                    local repo="${item#copr:}"
                    local pkgname="${repo#*:}"
                    repo="${repo%%:*}"
                    sudo ${bin} copr enable -y "${repo}"
                    sudo ${bin} install -y "${pkgname}"
                else
                    echo "skip ${item}: COPR only"
                fi
                ;;
            repofile:*)
                if [[ "${bin}" == "dnf" ]]; then
                    local rpurl="${item#repofile:}"
                    local rppkg="${rpurl##*:}"
                    rpurl="${rpurl%:*}"
                    sudo ${bin} config-manager addrepo --from-repofile="${rpurl}"
                    sudo ${bin} install -y "${rppkg}"
                else
                    echo "skip ${item}: repo file only"
                fi
                ;;
            *)
                case "${bin}" in
                    'pacman')
                        sudo ${bin} -S --noconfirm --needed "${item}"
                        ;;
                    'paru'|'yay')
                        ${bin} -S --noconfirm --needed "${item}"
                        ;;
                    'zypper')
                        sudo ${bin} -n install "${item}"
                        ;;
                    'apt')
                        sudo ${bin} install -y "${item}"
                        ;;
                    'dnf')
                        sudo ${bin} install -y "${item}"
                        ;;
                    *)
                        echo "unknown"
                        ;;
                esac
                ;;
        esac
    done
}

function remove {
    local bin="${1}"
    shift

    for item in "$@"; do
        case "${item}" in
            skip:*)
                echo "skip ${item#skip:}: not available on $(distro)"
                ;;
            aur:*)
                case "${bin}" in
                    'paru'|'yay')
                        ${bin} -Rs --noconfirm "${item#aur:}"
                        ;;
                    'pacman')
                        sudo ${bin} -Rs --noconfirm "${item#aur:}"
                        ;;
                    *)
                        echo "skip ${item#aur:}: AUR package, needs paru/yay"
                        ;;
                esac
                ;;
            copr:*)
                if [[ "${bin}" == "dnf" ]]; then
                    local pkgname="${item#copr:}"
                    pkgname="${pkgname#*:}"
                    sudo ${bin} remove -y "${pkgname}"
                else
                    echo "skip ${item}: COPR only"
                fi
                ;;
            repofile:*)
                if [[ "${bin}" == "dnf" ]]; then
                    local rppkg="${item##*:}"
                    sudo ${bin} remove -y "${rppkg}"
                else
                    echo "skip ${item}: repo file only"
                fi
                ;;
            *)
                case "${bin}" in
                    'pacman')
                        sudo ${bin} -Rs --noconfirm "${item}"
                        ;;
                    'paru'|'yay')
                        ${bin} -Rs --noconfirm "${item}"
                        ;;
                    'zypper')
                        sudo ${bin} -n rm "${item}"
                        ;;
                    'apt')
                        sudo ${bin} remove -y "${item}"
                        ;;
                    'dnf')
                        sudo ${bin} remove -y "${item}"
                        ;;
                    *)
                        echo "unknown"
                        ;;
                esac
                ;;
        esac
    done
}

# pass all args
main "$@"