#!/bin/bash

# copy into folder with files
# they will be normalized

# Requires
# ffmpeg

# https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg#1410620
# 


# Set normalization targets
TARGET_I=-16
TARGET_TP=-1.5
TARGET_LRA=11

# collect file list
FILES=()
while IFS= read -r -d '' FILE; do
    FILES+=("$FILE")
done < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -not -name "clean-*" -print0)


# normalise
for FILE in "${FILES[@]}"; do
 
    FILE="${FILE#./}"  # remove leading ./ from filename
    echo "Processing: $FILE"
    BASENAME="${FILE%.*}"
    EXT="${FILE##*.}"
    ANALYSIS_FILE="${BASENAME}.loudnorm.json"
    OUTFILE="clean-${BASENAME}.${EXT}"

    # fix timestamp/skipping issues
    #echo "Fixing timestamps..."
    #ffmpeg -fflags +genpts -i "$FILE" -c copy -avoid_negative_ts make_zero "fixed-$FILE"
    
    # normalization
    if [[ ! -f "$ANALYSIS_FILE" ]]; then
        echo "Running loudnorm analysis..."
        ffmpeg -hide_banner -nostdin -i "$FILE" \
            -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=json \
            -f null - 2>&1 | tee "$ANALYSIS_FILE" > /dev/null
    else
        echo "Using existing analysis: $ANALYSIS_FILE"
    fi
        
    # Extract loudnorm values from analysis JSON
    I=$(grep 'input_i' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    TP=$(grep 'input_tp' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    LRA=$(grep 'input_lra' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    THRESH=$(grep 'input_thresh' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OFFSET=$(grep 'target_offset' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    PERCENT=$(awk -v o="$OFFSET" 'BEGIN { printf "%.1f", (10^(o/10)) * 100 }')
    
    echo "Volume adjustment: ${OFFSET} LU (from ${I} LUFS to ${TARGET_I} LUFS)"
    echo "Volume change: $PERCENT%"
    
    
    # Get original audio codec and bitrate (bitrate might be empty for some formats)
    AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$FILE")
    AUDIO_BITRATE_RAW=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$FILE" || true)

    # Check codec is valid
    if [[ -z "$AUDIO_CODEC" ]]; then
        echo "Warn: Audio codec not detected. Using default 'aac'."
        AUDIO_CODEC="aac"
    fi

    # Map 'opus' codec to ffmpeg encoder name
    if [[ "$AUDIO_CODEC" == "opus" ]]; then
        AUDIO_CODEC="libopus"
    fi

    # Check and assign bitrate
    if [[ "$AUDIO_BITRATE_RAW" =~ ^[0-9]+$ ]]; then
        AUDIO_BITRATE="$((AUDIO_BITRATE_RAW / 1000))k"
    else
        # Set sensible defaults based on codec
        case "$AUDIO_CODEC" in
            libopus|opus)
                AUDIO_BITRATE="128k"
                ;;
            aac)
                AUDIO_BITRATE="192k"
                ;;
            *)
                AUDIO_BITRATE="160k"
                ;;
        esac
        echo "Warn: Bitrate unavailable. Using default: $AUDIO_BITRATE"
    fi


    # apply final normalization
    echo "Normalizing and encoding..."
    ffmpeg -nostdin -loglevel error -stats -i "$FILE" \
        -map 0 \
        -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:offset=$OFFSET:linear=true:print_format=summary \
        -c:v copy \
        -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" \
        -c:s copy \
        -c:d copy \
        "$OUTFILE"

    echo "Done: $OUTFILE"
    echo "------------------------------------"
    echo ""
done


# Cleanup
#rm -f "$TMPFILE"

echo "DONE!"
