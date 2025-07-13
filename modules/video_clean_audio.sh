#!/bin/bash

# copy this script into the folder with media video files
# they will be normalized and cleaned

# Requires:
# ffmpeg
# sox

# Thresholds
PEAK_THRESHOLD_DBFS=-1.1          # Needs gain if below this
DYN_RANGE_COMPAND_THRESHOLD=-30   # Needs compand if wider than this

# log fn
function log() {
    echo "$@" | tee -a "$logfile"
}

# collect file list
FILES=()
while IFS= read -r -d '' FILE; do
    FILES+=("$FILE")
done < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -not -name "clean-*" -print0)

# create ouput folder
mkdir -p clean

# process files
for FILE in "${FILES[@]}"; do
    FILE="${FILE#./}"  # remove leading ./ from filename
    BASENAME="${FILE%.*}"
    OUTFILE="clean/${BASENAME}.mp4"
    TMP_WAV="${BASENAME}.wav"
    TMP_PROC="${BASENAME}_proc.wav"
    TMP_LOG="${BASENAME}.sox"
    logfile="${BASENAME}.log"
    : > "$logfile"   # Clear previous log content
    log "$FILE"
    
    # Step 1: Extract audio to WAV
    if [[ ! -f "$TMP_WAV" ]]; then
        log "Extract audio..."
        ffmpeg -loglevel error -hide_banner -nostdin -stats -y -i "$FILE" -vn -acodec pcm_s16le -ar 44100 -ac 2 "$TMP_WAV"
    else
        log "Audio already extracted"
    fi
    
    # Step 2: Analyze audio
    log "Analyzing..."
    sox "$TMP_WAV" -n stats 2> "$TMP_LOG"
    
    MIN_VOL=$(awk '/^Min level/ {print $3}' "$TMP_LOG")
    MAX_VOL=$(awk '/^Max level/ {print $3}' "$TMP_LOG")
     
    if [[ -z "$MIN_VOL" || -z "$MAX_VOL" ]]; then
        log "Failed to detect volume. Will process anyway."
    fi
    
    # Calculate values
    RANGE=$(awk -v min="$MIN_VOL" -v max="$MAX_VOL" 'BEGIN { printf "%.6f", max - min }')
    ABS_MIN=$(awk -v v="$MIN_VOL" 'BEGIN { print (v < 0) ? -v : v }')
    ABS_MAX=$(awk -v v="$MAX_VOL" 'BEGIN { print (v < 0) ? -v : v }')
    ABS_RANGE=$(awk -v min="$ABS_MIN" -v max="$ABS_MAX" 'BEGIN { printf "%.6f", max - min }')

    # Convert to dBFS
    MIN_DBFS=$(awk -v a="$ABS_MIN" 'BEGIN { a = (a < 0) ? -a : a; if (a == 0) print "-inf"; else printf "%.2f", 20 * log(a)/log(10) }')
    MAX_DBFS=$(awk -v a="$ABS_MAX" 'BEGIN { a = (a < 0) ? -a : a; if (a == 0) print "-inf"; else printf "%.2f", 20 * log(a)/log(10) }')
    RANGE_DBFS=$(awk -v a="$ABS_RANGE" 'BEGIN { a = (a < 0) ? -a : a; if (a == 0) print "-inf"; else printf "%.2f", 20 * log(a)/log(10) }')

    log "Min amplitude     : $MIN_VOL ($MIN_DBFS dBFS)"
    log "Max amplitude     : $MAX_VOL ($MAX_DBFS dBFS)"
    log "Range             : $RANGE (approx $RANGE_DBFS dB)"
    log "Absolute range    : $ABS_RANGE ($RANGE_DBFS dBFS)"

    
    # Step 3: Decide if gain is needed based on peak level
    NEEDS_GAIN=false
    awk -v maxdb="$MAX_DBFS" -v thr="$PEAK_THRESHOLD_DBFS" 'BEGIN { if (maxdb < thr) exit 1 }'
    if [[ $? -eq 1 ]]; then
        NEEDS_GAIN=true
    fi
    
    
    # Step 4: Decide if compand is needed based on dynamic range
    NEEDS_COMPAND=false
    awk -v range="$RANGE_DBFS" -v comp="$DYN_RANGE_COMPAND_THRESHOLD" 'BEGIN { if (range < comp) exit 1 }'
    if [[ $? -eq 1 ]]; then
        NEEDS_COMPAND=true
    fi


    # Step 5: Apply appropriate processing
    if [[ "$NEEDS_GAIN" == true && "$NEEDS_COMPAND" == true ]]; then
        log "Applying compand + gain normalization..."
        sox "$TMP_WAV" "$TMP_PROC" compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 gain -n
    elif [[ "$NEEDS_GAIN" == true ]]; then
        log "Applying gain only..."
        sox "$TMP_WAV" "$TMP_PROC" gain -n
    else
        log "Audio is already loud and compact. Copying original..."
        cp "$TMP_WAV" "$TMP_PROC"
    fi

    
    # Step 6: Replace original audio with processed audio
    log "Replacing audio track in video..."
    ffmpeg -loglevel error -hide_banner -nostdin -y -i "$FILE" -i "$TMP_PROC" -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k "$OUTFILE"

    log "Ok"

    # Clean up
    rm -f "$TMP_WAV" "$TMP_PROC" "$TMP_LOG"
    
done

echo "DONE!"
