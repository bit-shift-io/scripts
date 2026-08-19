#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"


"$UTIL" -i opencode
# obsolete
#claude-code openai-codex antigravity-cli


echo "Complete"
