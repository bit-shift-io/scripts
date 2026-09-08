#!/bin/bash

# Prompt the user for the directory path
read -rp "Enter the path to the photo directory: " user_path

# Expand tilde if present
eval src_dir="$user_path"

# If the path doesn't start with /, assume it's relative to the home directory
if [[ "$src_dir" != /* ]]; then
    src_dir="$HOME/$src_dir"
fi

# Remove trailing slashes to keep paths clean
src_dir="${src_dir%/}"

# Check if the source directory exists
if [ ! -d "$src_dir" ]; then
    echo "Error: Directory '$src_dir' does not exist."
    exit 1
fi

dest_dir="${src_dir}_print"

# If the backup folder already exists, remove it first for a clean copy
if [ -d "$dest_dir" ]; then
    echo "Removing existing backup folder: $dest_dir"
    rm -rf "$dest_dir"
fi

# Create the fresh backup/print-ready folder
echo "Creating backup folder: $dest_dir"
cp -r "$src_dir" "$dest_dir"

# Recursively find and process all images by boosting shadow/black levels
echo "Optimizing photos (including subfolders) for printing..."
find "$dest_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heif" -o -iname "*.heic" \) | while read -r img; do
    echo "$img"
    magick "$img" +level 20%,100% "$img" # output levels like krita
    #magick "$img" -level 0%,100%,1.0,15% "$img" # shadow lift
    #magick "$img" -level 0%,100%,1.0,15% -modulate 110,100,100 "$img" # shadow lift + brightness 10%
    #magick "$img" -level 15%,100%,1.2 "$img" # dark lift, no good
    #magick "$img" -level 0%,100%,1.3 -modulate 115,100,100 "$img" # midlift ok
done

echo "Done! Print-ready photos are in: $dest_dir"
