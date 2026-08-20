#!/bin/bash

# Define default locations
LOCAL_HOME="/home/bronson"
DEFAULT_REMOTE_DIR="/mnt/media/2tb/BHome"

# Filter Rules (Evaluated in strict top-to-bottom order)
RCLONE_FILTERS=(
  # 1. EXCLUDE heavy internal caches inside allowed configs FIRST
  --filter "- /.config/google-chrome/**/Cache/**"
  --filter "- /.config/chromium/**/Cache/**"
  --filter "- /.config/mozilla/firefox/*/storage/default/**"
  --filter "- /.config/mozilla/firefox/*/startupCache/**"
  --filter "- /.config/mozilla/firefox/*/cache2/**"

  # 2. EXCLUDE development/build junk (Evaluated before root hidden drops)
  --filter "- **/node_modules/**"
  --filter "- **/target/**"
  --filter "- **/.venv/**"
  --filter "- **/__pycache__/**"

  # 3. INCLUDE critical hidden folders & files
  --filter "+ /.config/**"
  --filter "+ /.ssh/**"
  --filter "+ /.thunderbird/**"
  --filter "+ /.sourcegit/**"
  --filter "+ /.gnupg/**"
  --filter "+ /.gitconfig"

  # 4. EXCLUDE all other hidden files/folders at the root (~/.local, ~/.cache, etc.)
  --filter "- /.*"
  --filter "- /.**"

  # 5. INCLUDE EVERYTHING ELSE (Projects, Downloads, Desktop, Pictures, etc.)
  --filter "+ **"
)

# Base performance options (SAFE for both backup & restore)
BASE_OPTS=(
  -vP
  --fast-list
  --transfers 32
  --checkers 64
  --sftp-chunk-size 64k
  "${RCLONE_FILTERS[@]}"
)

# Prompt for remote path with a default fallback
read -p "Enter remote path [$DEFAULT_REMOTE_DIR]: " INPUT_REMOTE
REMOTE_DIR="${INPUT_REMOTE:-$DEFAULT_REMOTE_DIR}"

echo "b) Backup (Local -> Remote)"
echo "r) Restore (Remote -> Local)"
read -p "Enter choice: " choice

case $choice in
b)
    SRC_DIR="$LOCAL_HOME"
    DST_DIR="$REMOTE_DIR"
    MODE="BACKUP"
    RCLONE_CMD="sync"
    ACTION_OPTS=("--delete-excluded")
    ;;
r)
    SRC_DIR="$REMOTE_DIR"
    DST_DIR="$LOCAL_HOME"
    MODE="RESTORE"
    RCLONE_CMD="copy"
    ACTION_OPTS=()
    ;;
*)
    echo "Invalid option. Exiting."
    exit 1
    ;;
esac

echo "------------------------------------------------"
echo "Action: $MODE ($RCLONE_CMD)"
echo "Source: $SRC_DIR"
echo "Destination: $DST_DIR"
echo "------------------------------------------------"

read -n 1 -r -s -p "Press any key to continue..."
echo

rclone $RCLONE_CMD "${BASE_OPTS[@]}" "${ACTION_OPTS[@]}" "$SRC_DIR" "$DST_DIR"
echo "--- Finished $MODE $(date) ---"
