#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# ensure the tool is installed
"$UTIL" -i speedtest-cli

speedtest-cli