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


# normalise
for FILE in *.mp4; do
    echo "Processing: $FILE"
    BASENAME="${FILE%.*}"
    ANALYSIS_FILE="${BASENAME}.loudnorm.json"
    OUTFILE="normalized_${FILE}"

    if [[ ! -f "$ANALYSIS_FILE" ]]; then
        echo "Running loudnorm analysis..."
        ffmpeg -hide_banner -i "$FILE" \
            -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=json \
            -f null - 2> "$ANALYSIS_FILE"
    else
        echo "Using existing analysis: $ANALYSIS_FILE"
    fi
        
    # Extract loudnorm values from analysis JSON
    I=$(grep 'input_i' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    TP=$(grep 'input_tp' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    LRA=$(grep 'input_lra' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    THRESH=$(grep 'input_thresh' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OFFSET=$(grep 'target_offset' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')

    echo "Applying normalization to $OUTFILE..."

    ffmpeg -hide_banner -i "$FILE" \
        -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:offset=$OFFSET:linear=true:print_format=summary \
        -c:v copy -c:a aac -b:a 192k "$OUTFILE"

    echo "Done: $OUTFILE"
    echo "------------------------------------"
done


# Cleanup
#rm -f "$TMPFILE"

echo "DONE!"
