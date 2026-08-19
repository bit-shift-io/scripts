#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

run_module() {
    local name="$1"
    local mod="$MODULES_DIR/$name"
    if [[ -f "$mod" ]]; then
        bash "$mod"
    else
        echo "module not found: $name" >&2
        return 1
    fi
}

# pass args: each arg is a module filename to run directly
if [[ $# -ne 0 ]]; then
    for var in "$@"; do
        run_module "$var"
    done
    exit 0
fi

shopt -s nullglob
mods=( "$MODULES_DIR"/*.sh )
shopt -u nullglob

filtered=()
for m in "${mods[@]}"; do
    [[ "$(basename "$m")" == "util.sh" ]] && continue
    filtered+=("$m")
done

while true; do
    echo
    n=1
    current_group=""
    for m in "${filtered[@]}"; do
        name="$(basename "$m" .sh)"
        group="${name%%_*}"
        if [[ "$group" != "$current_group" ]]; then
            echo
            echo "$group"
            echo "-------------------"
            current_group="$group"
        fi
        display="${name#*_}"
        display="${display//_/ }"
        printf "%2d) %s\n" "$n" "$display"
        n=$((n+1))
    done
    echo
    read -rp "Select a number, q to quit: " choice || break
    case "$choice" in
        q|Q) break ;;
        ''|*[!0-9]*) echo "invalid selection" ;;
        *)
            idx=$((choice - 1))
            if (( idx >= 0 && idx < ${#filtered[@]} )); then
                mod="${filtered[$idx]}"
                if bash "$mod"; then
                    echo "done: $(basename "$mod")"
                else
                    echo "failed: $(basename "$mod") (exit $?)"
                fi
            else
                echo "invalid number"
            fi
            ;;
    esac
done