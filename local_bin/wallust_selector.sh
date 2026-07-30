#!/usr/bin/env bash
# ==============================================================================
# ARCHCRAFT++ WALLPAPER SELECTOR & WALLUST RECOLORING PIPELINE
# ==============================================================================

set -euo pipefail

WALL_DIR="${HOME}/Pictures/wallpapers"
CACHE_DIR="${HOME}/.cache/thumbnails/bgselector"

mkdir -p "$CACHE_DIR" "$WALL_DIR"

# Generate thumbnails and build Rofi menu input using Python for 100% path safety
ROFI_INPUT=$(python3 -c '
import os, glob

wall_dir = os.path.expanduser("~/Pictures/wallpapers")
cache_dir = os.path.expanduser("~/.cache/thumbnails/bgselector")
os.makedirs(cache_dir, exist_ok=True)

valid_exts = (".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp")
items = []

for root, dirs, files in os.walk(wall_dir):
    for f in files:
        if f.lower().endswith(valid_exts):
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, wall_dir)
            cache_name = rel_path.replace("/", "_").replace("\\", "_") + ".jpg"
            cache_path = os.path.join(cache_dir, cache_name)
            
            if not os.path.exists(cache_path):
                os.system(f"magick \"{full_path}[0]\" -thumbnail 330x540^ -gravity center -extent 330x540 -quality 80 \"{cache_path}\" 2>/dev/null")
            
            if os.path.exists(cache_path):
                items.append((rel_path, cache_path))

items.sort(key=lambda x: x[0].strip().lower())

for rel_path, cache_path in items:
    print(f"{rel_path}\0icon\x1f{cache_path}")
')

if [[ -z "$ROFI_INPUT" ]]; then
    notify-send "Wallpaper Selector" "No wallpapers found in ~/Pictures/wallpapers" -i dialog-warning
    exit 1
fi

# Display Rofi thumbnail grid picker
SELECTED=$(printf "%s" "$ROFI_INPUT" | rofi -dmenu -i -p "Select Wallpaper" -show-icons -config "$HOME/.config/rofi/bgselector/style.rasi" || true)

if [[ -n "$SELECTED" ]]; then
    SELECTED_PATH="$WALL_DIR/$SELECTED"
    if [[ -f "$SELECTED_PATH" ]]; then
        echo "[INFO] Applying selected wallpaper: $SELECTED_PATH"
        
        if command -v nitrogen >/dev/null 2>&1; then
            nitrogen --set-zoom-fill --save "$SELECTED_PATH" 2>/dev/null || true
        elif command -v feh >/dev/null 2>&1; then
            feh --bg-fill "$SELECTED_PATH" 2>/dev/null || true
        fi
        
        # Trigger Theme Synchronization
        "$HOME/.config/openbox/scripts/theme-sync.sh" "$SELECTED_PATH"
    fi
fi
