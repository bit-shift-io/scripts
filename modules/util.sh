#!/bin/bash

# Resolve the repo root so modules work from any directory
MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$MODULES_DIR")"

# Export UTIL so it points to the executable root script
export UTIL="$ROOT_DIR/util.sh"

# Source the functions so they are available if sourced directly
source "$UTIL"
