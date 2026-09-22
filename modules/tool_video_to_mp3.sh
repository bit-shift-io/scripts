#!/bin/bash
set -euo pipefail

# copy into folder with video files
# they will be converted into mp3

# Requires ffmpeg

# Create dir to store mp3 files if it doesn't exist
# First get the current directory name
current_dir=$(pwd)
base_name=$(basename "$current_dir")

mkdir -p "${base_name}-mp3"
echo ""

# Convert videos to mp3 audio files
find . -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" | while read -r file; do
    ffmpeg -i "$file" -b:a 320K -vn "${base_name}-mp3/${file}.mp3"
done

# remove video extensions
cd "${base_name}-mp3"

shopt -s nullglob
for file_name in *; do
    mv "$file_name" "$(echo "$file_name" | sed 's/\.mp4//g;s/\.mkv//g;s/\.webm//g')"
done

echo ""
echo "All files converted successfully"