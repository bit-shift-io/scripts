#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# requires kernel headers matching the running kernel
"$UTIL" -i rtl88x2bu-dkms-git