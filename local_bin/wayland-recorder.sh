#!/usr/bin/env bash
# ==============================================================================
# WAYLAND NATIVE SCREEN RECORDER PIPELINE (NIRI / WAYLAND COMPATIBLE)
# ==============================================================================

set -euo pipefail

SAVE_DIR="${HOME}/Videos/Recordings"
mkdir -p "$SAVE_DIR"

if pgrep -x "wf-recorder" >/dev/null; then
    pkill -SIGINT -x "wf-recorder"
    notify-send -i media-record "Screen Recorder" "Recording stopped and saved to ~/Videos/Recordings/"
else
    TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
    OUTPUT_FILE="${SAVE_DIR}/recording_${TIMESTAMP}.mp4"
    
    notify-send -i media-record "Screen Recorder" "Recording started... Press Super+Shift+R to stop."
    
    wf-recorder -f "$OUTPUT_FILE" >/dev/null 2>&1 &
fi
