#!/bin/bash
set -euo pipefail

# disable broken kde search
if command -v balooctl > /dev/null 2>&1; then
    balooctl disable
fi

if command -v notify-send > /dev/null 2>&1; then
    notify-send 'Config' 'KDE config complete'
fi