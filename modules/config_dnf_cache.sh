#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# installs the dnf plugin for building a local repo from a directory of RPMs
"$UTIL" -i python3-dnf-plugin-local