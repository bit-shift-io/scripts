#!/usr/bin/env bash

# Base projects directory
PROJECTS_BASE="$HOME/Projects"

# Defaults
FOLDER_NAME=""
SESSION_ID=""

# Parse positional arguments
if [[ $# -ge 1 ]]; then
    FOLDER_NAME="$1"
fi
if [[ $# -ge 2 ]]; then
    SESSION_ID="$2"
fi

# Fall back to default folder if none was provided
FOLDER_NAME="${FOLDER_NAME:-fido-and-kitch}"

# Construct full project path
PROJECT_DIR="$PROJECTS_BASE/$FOLDER_NAME"

# Build the opencode command dynamically
OPENCODE_CMD="opencode"
if [[ -n "$SESSION_ID" ]]; then
    OPENCODE_CMD="opencode -s $SESSION_ID"
fi

# Name of the tmux session and log location
SESSION_NAME="opencode"
LOG_FILE="$HOME/opencode-retry.log"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "[Error] Directory '$PROJECT_DIR' does not exist."
    exit 1
fi

# Function to log messages with timestamps
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_event "[Info] Starting script session wrapper..."

# 1. Start tmux session in the background targeting PROJECT_DIR
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    log_event "[Info] Starting tmux session '$SESSION_NAME' in '$PROJECT_DIR' with command: '$OPENCODE_CMD'..."
    tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" "$OPENCODE_CMD"
fi

# 2. Start background watcher loop
(
    while tmux has-session -t "$SESSION_NAME" 2>/dev/null; do
        if tmux capture-pane -pt "$SESSION_NAME" -S -10 2>/dev/null | grep -q "Streaming response failed"; then # capture last 10 lines of the pane
            log_event "[DETECTED] 'Streaming response failed' string found in pane!"
            log_event "[WAITING] Sleeping 5 minutes (300s) before resending continue..."

            sleep 300

            if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                log_event "[ACTION] Sending 'continue' to tmux session..."
                tmux send-keys -t "$SESSION_NAME" "continue" Enter
            else
                log_event "[WARN] Session died during wait. Skipping send."
            fi

            # Prevent immediate re-triggering while output streams
            sleep 30
        fi
        sleep 5
    done
    log_event "[Info] Session '$SESSION_NAME' ended. Watcher exiting."
) &

# 3. Attach to the session
log_event "[Info] Attaching to session '$SESSION_NAME'..."
tmux attach-session -t "$SESSION_NAME"
