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

# log fn
function log() {
    echo "$@" | tee -a "$logfile"
}

# collect file list
FILES=()
while IFS= read -r -d '' FILE; do
    FILES+=("$FILE")
done < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -not -name "clean-*" -print0)


# normalise
for FILE in "${FILES[@]}"; do
    FILE="${FILE#./}"  # remove leading ./ from filename
    BASENAME="${FILE%.*}"
    EXT="${FILE##*.}"
    ANALYSIS_FILE="${BASENAME}.loudnorm.json"
    OUTFILE="clean-${BASENAME}.${EXT}"
    logfile="${BASENAME}.log"
    
    log "$FILE"
    
    # check channels
    # possibly downmix
    CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$FILE")
    if [[ "$CHANNELS" -gt 2 ]]; then
        log "Warn: File has $CHANNELS audio channels (not stereo), consider downmixing."
    fi

    # fix timestamp/skipping issues
    #log "Fixing timestamps..."
    #ffmpeg -fflags +genpts -i "$FILE" -c copy -avoid_negative_ts make_zero "fixed-$FILE"
    
    # normalization
    if [[ ! -f "$ANALYSIS_FILE" ]]; then
        log "Running loudnorm analysis..."
        ffmpeg -hide_banner -nostdin -i "$FILE" \
            -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=json \
            -f null - 2>&1 | tee "$ANALYSIS_FILE" > /dev/null
    else
        log "Skip loudnorm, use existing analysis."
    fi
        
    # Extract loudnorm values from analysis JSON
    I=$(grep 'input_i' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    TP=$(grep 'input_tp' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    LRA=$(grep 'input_lra' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    THRESH=$(grep 'input_thresh' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OFFSET=$(grep 'target_offset' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OUTPUT_I=$(grep '"output_i"' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OUTPUT_TP=$(grep '"output_tp"' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OUTPUT_LRA=$(grep '"output_lra"' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    OUTPUT_THRESH=$(grep '"output_thresh"' "$ANALYSIS_FILE" | sed 's/.*: //;s/[",]//g')
    NORMALIZATION_TYPE=$(grep '"normalization_type"' "$ANALYSIS_FILE" | sed 's/.*: "//;s/".*//')
    
    log ""
    log "Pre-normalization loudness:"
    {
        echo "Input Integrated:    ${I} LUFS"
        echo "Input True Peak:     ${TP} dBTP"
        echo "Input LRA:           ${LRA} LU"
        echo "Input Threshold:     ${THRESH} LUFS"
        echo "Output Integrated:   ${OUTPUT_I} LUFS"
        echo "Output True Peak:    ${OUTPUT_TP} dBTP"
        echo "Output LRA:          ${OUTPUT_LRA} LU"
        echo "Output Threshold:    ${OUTPUT_THRESH} LUFS"
        echo "Normalization Type:  ${NORMALIZATION_TYPE}"
        echo "Target Offset:       ${OFFSET} LU"
    } | tee -a "$logfile"
    log ""
    
    
    # Calculate simple LUFS difference
    log ""
    log "Changes to make:"
    LU_DIFFERENCE=$(awk -v i="$I" -v t="$TARGET_I" 'BEGIN { printf "%.2f", t - i }')
    # Calculate volume change based on LUFS difference (not offset)
    PERCENT=$(awk -v o="$LU_DIFFERENCE" 'BEGIN { printf "%.1f", (10^(o/20)) * 100 }')
    CHANGE=$(awk -v p="$PERCENT" 'BEGIN { printf "%.1f", (p > 100) ? p - 100 : 100 - p }')

    # Determine increase or decrease
    if awk "BEGIN {exit !($PERCENT > 100)}"; then
        log "Volume adjustment: ${LU_DIFFERENCE} LU from ${I} LUFS to ${TARGET_I} LUFS"
        log "Volume change: $CHANGE% increase"
    else
        log "Volume adjustment: ${LU_DIFFERENCE} LU from ${I} LUFS to ${TARGET_I} LUFS"
        log "Volume change: $CHANGE% decrease"
        log "Skipping"
        log ""
        continue
    fi
    
    # skip if close
    if awk "BEGIN {exit !(sqrt(($LU_DIFFERENCE)^2) < 0.5)}"; then
        log "Input already close to target loudness."
        log "Skipping"
        log ""
        continue
    fi
    
    # Warn if input True Peak is dangerously high (from .json)
    if awk "BEGIN {exit !($TP > 1.0)}"; then
        log "Warn: Input audio likely clipped (TP = ${TP} dBTP), consider remastering or applying stronger compression first."
    fi

    
    # Get original audio codec and bitrate (bitrate might be empty for some formats)
    AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$FILE")
    AUDIO_BITRATE_RAW=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$FILE" || true)

    # Check codec is valid
    if [[ -z "$AUDIO_CODEC" ]]; then
        log "Warn: Audio codec not detected. Using default 'aac'."
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
        log "Warn: Bitrate unavailable. Using default: $AUDIO_BITRATE"
    fi


    # Convert TARGET_TP (in dB) to linear gain for alimiter
    TP_LIMIT=$(awk -v db="$TARGET_TP" 'BEGIN { printf "%.3f", 10^(db / 20) }')
    
    # apply final normalization
    log ""
    log "Normalizing and encoding..."
    ffmpeg -nostdin -loglevel error -stats -i "$FILE" \
        -map 0 \
        -af "volume=-3dB,acompressor=threshold=-12dB:ratio=3:attack=10:release=250,loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:offset=$OFFSET:linear=false,alimiter=limit=$TP_LIMIT" \
        -c:v copy \
        -c:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE" \
        -c:s copy \
        -c:d copy \
        "$OUTFILE"
        
    # Move and rename the normalized file
    mkdir -p clean
    mv "$OUTFILE" "clean/${BASENAME}.${EXT}"
    log "Normalize complete"

    
    # Post-normalization loudness check
    log ""
    log "Verifying normalized output loudness..."
    TMP_LOUDNESS_CHECK=$(mktemp)
    ffmpeg -hide_banner -nostdin -i "$OUTFILE" \
        -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=summary \
        -f null - 2> "$TMP_LOUDNESS_CHECK"
    #ffmpeg -hide_banner -nostdin -i "$OUTFILE" \
    #    -af loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=summary \
    #    -f null - 2>&1 | tee "$TMP_LOUDNESS_CHECK" > /dev/null
        
    # Extract only the summary (non-ffmpeg noise) and append to the log
    log ""
    log "Post-check summary:"
    grep -E 'Input (Integrated|True Peak|LRA|Threshold)|Output (Integrated|True Peak|LRA|Threshold)|Normalization Type|Target Offset' "$TMP_LOUDNESS_CHECK" | tee -a "$logfile" > /dev/null
    #rm -f "$TMP_LOUDNESS_CHECK"
    echo "$TMP_LOUDNESS_CHECK"
    log ""
done


# Cleanup
#rm -f "$TMPFILE"

echo "DONE!"
