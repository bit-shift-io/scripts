#!/usr/bin/env bash

# Define target project directory (defaults to current directory if not set)
PROJECT_DIR="${1:-$HOME/Projects/rosetta}"

# Name of the tmux session and log location
SESSION_NAME="opencode"
LOG_FILE="$HOME/opencode-retry.log"

# Expand relative paths or ~ to absolute paths
PROJECT_DIR="$(eval echo "$PROJECT_DIR")"

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
    log_event "[Info] Starting tmux session '$SESSION_NAME' in '$PROJECT_DIR'..."
    tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" "opencode"
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
