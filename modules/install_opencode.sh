#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"


if [[ "$(distro)" == "fedora" ]]; then
    # the fedora build is currently broken, install via the official script instead
    curl -fsSL https://opencode.ai/install | bash
else
    "$UTIL" -i opencode
fi


echo "Complete"
