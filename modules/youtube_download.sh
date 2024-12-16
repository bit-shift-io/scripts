#!/bin/bash

./util.sh -i yt-dlp

# todo: menu video/audio

echo "Paste URL "
read URL

cd $HOME

# audio
yt-dlp --split-chapters -x --audio-format mp3 "$URL"

echo "Complete"
