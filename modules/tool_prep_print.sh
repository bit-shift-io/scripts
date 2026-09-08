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

# Create the backup/print-ready folder
echo "Creating backup folder: $dest_dir"
cp -r "$src_dir" "$dest_dir"

# Recursively find and process all images inside the backup folder, printing the filename
echo "Optimizing photos (including subfolders) for printing..."
find "$dest_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r img; do
    echo "Processing: $img"
    magick "$img" -auto-gamma -auto-level "$img"
done

echo "Done! Print-ready photos are in: $dest_dir"
