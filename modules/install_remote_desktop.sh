#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../util.sh"
UTIL="$(dirname "${BASH_SOURCE[0]}")/../util.sh"


"$UTIL" -i krdc krdp


echo "Complete"
