#!/bin/bash

# Find the directory of *this* proxy script (modules folder)
PROXY_DIR=$(dirname "$(readlink -f "$BASH_SOURCE[0]")")

# Navigate up one directory to reach the root
ROOT_DIR=$(dirname "$PROXY_DIR")

# Source the main utility script in the root directory
source "$ROOT_DIR/util.sh"
