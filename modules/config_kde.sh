#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"

# disable broken kde search
if command -v balooctl > /dev/null 2>&1; then
    balooctl disable
fi

notify 'Config' 'KDE config complete'