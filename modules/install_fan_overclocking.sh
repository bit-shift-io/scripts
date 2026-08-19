#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

"$UTIL" -i lact corectrl coolercontrol-bin

echo "Complete"
