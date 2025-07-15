#!/bin/bash

# copy this script into the folder with media video files
# they will be normalized and cleaned

# Requires:
# ffmpeg
# sox

# Thresholds
PEAK_THRESHOLD_DBFS=-1.1         # Needs gain if below this
DYN_RANGE_COMPAND_THRESHOLD=30   # Needs compand if wider than this
LOG_FILE="video_clean_audio.log"
TMPDIR="tmp"
CLEANDIR="clean"

function log() {
    echo "$@" | tee -a "$LOG_FILE"
}


function abs() {
    local val="$1"
    awk -v x="$val" 'BEGIN { print (x < 0) ? -x : x }'
}
    
function to_dbfs() {
    local val="$1"
    awk -v a="$val" 'BEGIN {
        if (a <= 0) print "-inf";
        else printf "%.2f", 20 * log(a) / log(10);
    }'
}


function analyze_audio_stats() {
    local wav_file="$1"
    local stats_log="$2"

    sox "$wav_file" -n stats 2> "$stats_log"

    PEAK_LEVEL_DBFS=$(awk '/^Pk lev dB/ {print $(NF-2)}' "$stats_log")
    RMS_LEVEL_DBFS=$(awk '/^RMS lev dB/ {print $(NF-2)}' "$stats_log")
    
    # Approximate dynamic range (Crest factor in dB)
    if [[ "$PEAK_LEVEL_DBFS" =~ ^-?[0-9.]+$ && "$RMS_LEVEL_DBFS" =~ ^-?[0-9.]+$ ]]; then
        DYNAMIC_RANGE_DBFS=$(awk -v peak="$PEAK_LEVEL_DBFS" -v rms="$RMS_LEVEL_DBFS" \
            'BEGIN { printf "%.2f", peak - rms }')
    else
        DYNAMIC_RANGE_DBFS="n/a"
    fi

    log "Peak level (dB)    : $PEAK_LEVEL_DBFS"
    log "RMS level (dB)     : $RMS_LEVEL_DBFS"
    log "Dynamic Range (dB) : $DYNAMIC_RANGE_DBFS"
    
    export PEAK_LEVEL_DBFS RMS_LEVEL_DBFS DYNAMIC_RANGE_DBFS
}


function clean_temp_files() {
    rm -rf "$TMPDIR"
}
trap cleanup_temp_files EXIT

# collect file list
FILES=()
while IFS= read -r -d '' FILE; do
    FILES+=("$FILE")
done < <(find . -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -not -name "clean-*" -print0)

# create ouput folders
mkdir -p "$TMPDIR" "$CLEANDIR"
: > "$LOG_FILE"   # Clear previous log content

# process files
for FILE in "${FILES[@]}"; do
    FILE="${FILE#./}"  # remove leading ./ from filename
    BASENAME="${FILE%.*}"
    OUTFILE="$CLEANDIR/${BASENAME}.mp4"
    TMP_WAV="$TMPDIR/${BASENAME}.wav"
    TMP_PROC="$TMPDIR/${BASENAME}_proc.wav"
    TMP_LOG="$TMPDIR/${BASENAME}.sox"
    
    log "--------------------"
    log ""
    log "$FILE"
    

    #log "Audio codec info:"
    #ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,bit_rate \
    #    -of default=noprint_wrappers=1 "$FILE" | tee -a "$logfile"
        
    CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$FILE")
    if [[ "$CHANNELS" -gt 2 ]]; then
        log "Warn: $CHANNELS channels - downmixing"
    fi

    
    # Extract audio to WAV
    log ""
    if [[ ! -f "$TMP_WAV" ]]; then
        log "Extracting audio..."
        ffmpeg -loglevel error -err_detect ignore_err -hide_banner -nostdin -stats -y -i "$FILE" -vn -acodec pcm_s16le -ar 44100 -ac 2 "$TMP_WAV"
    else
        log "Use existing audio..."
    fi
    
    
    # Analyze audio
    log ""
    log "Analyzing audio..."
    analyze_audio_stats "$TMP_WAV" "$TMP_LOG"

    
    # Decide if gain is needed based on peak level
    NEEDS_GAIN=false
    awk -v maxdb="$PEAK_LEVEL_DBFS" -v thr="$PEAK_THRESHOLD_DBFS" 'BEGIN { if (maxdb < thr) exit 1 }'
    if [[ $? -eq 1 ]]; then
        NEEDS_GAIN=true
    fi
    
    
    # Decide if compand is needed based on dynamic range
    NEEDS_COMPAND=false
    awk -v range="$DYNAMIC_RANGE_DBFS" -v comp="$DYN_RANGE_COMPAND_THRESHOLD" 'BEGIN { if (range > comp) exit 1 }'
    if [[ $? -eq 1 ]]; then
        NEEDS_COMPAND=true
    fi


    # Apply appropriate processing
    log ""
    if [[ "$NEEDS_GAIN" == true && "$NEEDS_COMPAND" == true ]]; then
        log "Applying compression + gain..."
        # for now, just do the gain
        #sox "$TMP_WAV" "$TMP_PROC" compand 0.3,1 6:-70,-60,-20 -5 -90 0.2 gain -n -0.1
        sox "$TMP_WAV" "$TMP_PROC" gain -n -0.1
    elif [[ "$NEEDS_GAIN" == true ]]; then
        log "Applying gain..."
        sox "$TMP_WAV" "$TMP_PROC" gain -n -0.1
    else
        log "Audio is already loud and within range. Skipping"
        continue
    fi
    
    # Analyze result
    log ""
    log "Analyzing modified audio..."
    analyze_audio_stats "$TMP_PROC" "$TMP_LOG"
    
    # Replace original audio with processed audio
    log ""
    log "Replacing audio in video..."
    ffmpeg -loglevel error -hide_banner -nostdin -y -i "$FILE" -i "$TMP_PROC" -map 0:v -map 1:a -c:v copy -c:a aac -b:a 192k "$OUTFILE"

    log "Ok"
    log ""
    
done

clean_temp_files
log "--------------------"
log "DONE!"
