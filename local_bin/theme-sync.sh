#!/usr/bin/env bash
# ==============================================================================
# ARCHCRAFT++ THEME-SYNC.SH - Dynamic Color Synchronizer
# ==============================================================================

set -euo pipefail

WALLPAPER_PATH="${1:-}"

# If no wallpaper argument, read from nitrogen's current background configuration
if [[ -z "$WALLPAPER_PATH" && -f "$HOME/.config/nitrogen/bg-saved.cfg" ]]; then
    WALLPAPER_PATH=$(grep -m1 '^file=' "$HOME/.config/nitrogen/bg-saved.cfg" | cut -d'=' -f2-)
fi

if [[ -n "$WALLPAPER_PATH" && -f "$WALLPAPER_PATH" ]]; then
    echo "[INFO] Extracting color palette from: $WALLPAPER_PATH"
    wal -i "$WALLPAPER_PATH" -n -q || true
    python3 "$HOME/.config/openbox/scripts/pywal_to_wallust.py"
else
    echo "[WARN] No valid wallpaper found."
fi

# 1. Refresh Kitty Terminals
if command -v kitty >/dev/null 2>&1; then
    kitty @ set-colors -a "$HOME/.config/kitty/colors.conf" 2>/dev/null || killall -USR1 kitty 2>/dev/null || true
fi

# 2. Refresh Alacritty (Alacritty auto-reloads upon colors.toml modification)

# 3. Refresh Polybar
if pgrep -x polybar >/dev/null; then
    polybar-msg cmd restart 2>/dev/null || ("$HOME/.config/openbox/themes/polybar.sh" 2>/dev/null &)
fi

# 4. Refresh Dunst Notifications
if pgrep -x dunst >/dev/null; then
    dunstctl reload 2>/dev/null || (killall dunst 2>/dev/null && dunst &)
fi

# 5. Send Desktop Notification
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Dynamic Recolor Sync" "System theme updated to match wallpaper!" -i preferences-desktop-theme 2>/dev/null || true
fi

echo "[SUCCESS] Dynamic theme synchronization completed."
