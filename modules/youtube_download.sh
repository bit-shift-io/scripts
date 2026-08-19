#!/bin/bash
# todo get a whole channel/playlist
# https://techearl.com/download-youtube-playlist
# https://askubuntu.com/questions/856911/using-youtube-dl-to-download-entire-youtube-channel
#
# get the entire channel/playlist, we want /videos
# yt-dlp "https://www.youtube.com/@channelhandle"
# yt-dlp "https://www.youtube.com/playlist?list=PLAYLIST_ID"
#
# keep track of what has been downloaded
# yt-dlp --download-archive archive.txt "https://www.youtube.com/@channelhandle"
#
# rate limit, with random so we dont look like a scraper
# yt-dlp -r 3M --sleep-requests 1 --download-archive archive.txt "URL"
#
# clean file names
# yt-dlp -o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" "URL"
#


# set some variables
DL_DIR="$HOME/youtube"
MAX_RES=720 # Maximum vertical resolution (e.g. 720, 1080)
mkdir -p "$DL_DIR"

function main {
    # loop args
    if [[ $# -ne 0 ]] ; then
        for var in "$@" ; do
            $var
        done
        exit 1
    fi

    # menu
    while true; do
    read -n 1 -p "
    a) Audio
    v) Video
    c) Channel

    *) Any key to exit
    :" ans;
    reset
    case $ans in
        a) fn_user_input audio ;;
        v) fn_user_input video ;;
        c) fn_user_input channel ;;
        *) $SHELL ;;
    esac
    done
}

function fn_util_check {
    # ensure the tool is installed
    ./util.sh -i yt-dlp
}

function fn_user_input {
    echo "Paste youtube link: "
    read URL

    case $1 in
        audio) fn_get_audio ;;
        video) fn_get_video ;;
        channel) get_channel ;;
    esac
}

function get_channel {
    cd "$DL_DIR"

    # append /videos if it's a channel link
    if [[ "$URL" =~ youtube\.com/@[^/]+$ ]]; then
        URL="${URL}/videos"
    fi

    yt-dlp \
        -f "bestvideo[height<=${MAX_RES}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${MAX_RES}][ext=mp4]/best[height<=${MAX_RES}]" \
        -r 1M \
        --sleep-requests 1 \
        --min-sleep-interval 1 \
        --max-sleep-interval 5 \
        --download-archive "$DL_DIR/archive.txt" \
        -o "%(playlist_title|Channel)s/%(playlist_index)s - %(title)s.%(ext)s" \
        "$URL"
}

function fn_get_video {
    cd "$DL_DIR"

    yt-dlp \
        --no-playlist \
        -f "bestvideo[height<=${MAX_RES}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${MAX_RES}][ext=mp4]/best[height<=${MAX_RES}]" \
        --download-archive "$DL_DIR/archive.txt" \
        -o "%(title)s.%(ext)s" \
        "$URL"
    echo "Complete"
}

function fn_get_audio {
    cd "$DL_DIR"

    yt-dlp \
        --no-playlist \
        --split-chapters \
        -x \
        --audio-format mp3 \
        --audio-quality 0 \
        --download-archive "$DL_DIR/archive.txt" \
        -o "%(title)s.%(ext)s" \
        "$URL"
    echo "Complete"
}


# pass all args
main "$@"
