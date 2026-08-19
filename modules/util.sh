#!/bin/bash

# Resolve the repo root so modules work from any directory
MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$MODULES_DIR")"
UTIL="$ROOT_DIR/util.sh"