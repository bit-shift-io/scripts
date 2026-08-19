#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# https://forum.manjaro.org/t/chinese-language-support/115416/5
"$UTIL" -i adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts
"$UTIL" -i fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-chinese-addons manjaro-asian-input-support-fcitx5