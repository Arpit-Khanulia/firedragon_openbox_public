#!/usr/bin/env bash
# ==============================================================================
# ARCHCRAFT++ WALLPAPER SELECTOR & WALLUST RECOLORING PIPELINE
# ==============================================================================

set -euo pipefail

WALL_DIR="${HOME}/Pictures/wallpapers"
CACHE_DIR="${HOME}/.cache/thumbnails/bgselector"
CACHE_INDEX="${CACHE_DIR}/.index"

mkdir -p "$CACHE_DIR" "$WALL_DIR"

# Build list of wallpapers
current_index=$(mktemp)
find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) -printf '%p\n' > "$current_index"

# Generate thumbnails in parallel
max_jobs=$(nproc 2>/dev/null || echo 4)

generate_thumbnail() {
    local img="$1"
    local cache_dir="$2"
    local wall_dir="$3"
    
    local rel_path="${img#$wall_dir/}"
    local cache_name="${rel_path//\//_}"
    cache_name="${cache_name%.*}.jpg"
    local cache_file="$cache_dir/$cache_name"
    
    if [[ ! -f "$cache_file" ]]; then
        magick "$img[0]" -thumbnail 330x540^ -gravity center -extent 330x540 -quality 80 "$cache_file" 2>/dev/null || true
    fi
}
export -f generate_thumbnail

if command -v xargs >/dev/null 2>&1; then
    cat "$current_index" | xargs -P "$max_jobs" -I {} bash -c 'generate_thumbnail "$1" "$2" "$3"' _ {} "$CACHE_DIR" "$WALL_DIR"
fi

# Build Rofi menu input
rofi_input=$(mktemp)
while read -r img; do
    rel_path="${img#$WALL_DIR/}"
    cache_name="${rel_path//\//_}"
    cache_name="${cache_name%.*}.jpg"
    cache_file="$CACHE_DIR/$cache_name"
    
    if [[ -f "$cache_file" ]]; then
        printf '%s\000icon\037%s\n' "$rel_path" "$cache_file"
    fi
done < "$current_index" > "$rofi_input"

rm -f "$current_index"

# Display Rofi picker
selected=$(rofi -dmenu -i -p "Select Wallpaper" -show-icons -config "$HOME/.config/rofi/bgselector/style.rasi" < "$rofi_input" || true)
rm -f "$rofi_input"

# Apply selected wallpaper & trigger Wallust recoloring
if [[ -n "$selected" ]]; then
    selected_path="$WALL_DIR/$selected"
    if [[ -f "$selected_path" ]]; then
        echo "[INFO] Applying wallpaper: $selected_path"
        
        if command -v nitrogen >/dev/null 2>&1; then
            nitrogen --set-zoom-fill --save "$selected_path" 2>/dev/null || true
        elif command -v feh >/dev/null 2>&1; then
            feh --bg-fill "$selected_path" 2>/dev/null || true
        fi
        
        # Trigger Theme Synchronization
        "$HOME/.config/openbox/scripts/theme-sync.sh" "$selected_path"
    fi
fi
