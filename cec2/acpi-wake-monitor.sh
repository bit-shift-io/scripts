#!/bin/bash
# ACPI Wake Event Monitor
# Listens for ACPI wake events and triggers TV wake
# Runs as a systemd service

SCRIPT_DIR="/home/server/Projects/scripts/cec2"
LOG_FILE="/var/log/cec-wake-detection.log"

log_message() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ACPI-MONITOR] $msg" | tee -a "$LOG_FILE"
}

log_message "=== ACPI Wake Monitor started ==="

# Check if acpi_listen is available
if ! command -v acpi_listen &> /dev/null; then
    log_message "ERROR: acpi_listen not found. Install acpi package."
    exit 1
fi

# Check if acpid is running
if ! systemctl is-active --quiet acpid; then
    log_message "WARNING: acpid not running. Attempting to start..."
    sudo systemctl start acpid
    sleep 2
fi

log_message "acpid status: $(systemctl is-active acpid)"

# Monitor ACPI events
acpi_listen | while read event; do
    log_message "ACPI Event received: $event"

    # Detect wake-related events
    if [[ "$event" =~ "button/power" ]] || \
       [[ "$event" =~ "button/sleep" ]] || \
       [[ "$event" =~ "button/lid" ]] || \
       [[ "$event" =~ "battery" ]] || \
       [[ "$event" =~ "ac_adapter" ]] || \
       [[ "$event" =~ "button/wake" ]]; then

        log_message "WAKE EVENT DETECTED: $event - turning on TV"
        "$SCRIPT_DIR/wakeUp.sh" >> "$LOG_FILE" 2>&1
        log_message "wakeUp.sh executed"
    else
        log_message "Other ACPI event (ignored): $event"
    fi
done
