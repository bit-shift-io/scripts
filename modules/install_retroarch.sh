#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"


# install waydroid
"$UTIL" -i retroarch retroarch-assets-ozone retroarch-assets-xmb


echo "Complete"
