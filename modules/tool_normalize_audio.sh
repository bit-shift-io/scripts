#!/bin/bash
set -euo pipefail

# copy into folder with music files
# they will be normalized

# Requires ffmpeg

shopt -s nullglob
for f in *.mp3; do
    echo "$f"
    ffmpeg -i "$f" -af loudnorm=I=-16:LRA=11:TP=-1.5 "tmp-$f"
    mv -f "tmp-$f" "$f"
done
echo "DONE!"