#!/usr/bin/env python3
# ==============================================================================
# PYWAL TO WALLUST TEMPLATE ENGINE FOR ARCHCRAFT++
# ==============================================================================

import json
import os

wal_cache = os.path.expanduser("~/.cache/wal/colors.json")
if not os.path.exists(wal_cache):
    print("No wal colors.json found.")
    exit(1)

with open(wal_cache, "r") as f:
    data = json.load(f)

bg = data["special"]["background"]
fg = data["special"]["foreground"]
cursor = data["special"].get("cursor", fg)
colors = data["colors"]

tokens = {
    "background": bg,
    "foreground": fg,
    "cursor": cursor,
}

for i in range(16):
    tokens[f"color{i}"] = colors.get(f"color{i}", bg)

def safe_write(filepath, content):
    os.makedirs(os.path.dirname(os.path.expanduser(filepath)), exist_ok=True)
    with open(os.path.expanduser(filepath), "w") as f:
        f.write(content)

# Render Kitty
kitty_conf = f"""cursor {tokens['cursor']}
foreground {tokens['foreground']}
background {tokens['background']}

color0  {tokens['color0']}
color8  {tokens['color8']}
color1  {tokens['color1']}
color9  {tokens['color9']}
color2  {tokens['color2']}
color10 {tokens['color10']}
color3  {tokens['color3']}
color11 {tokens['color11']}
color4  {tokens['color4']}
color12 {tokens['color12']}
color5  {tokens['color5']}
color13 {tokens['color13']}
color6  {tokens['color6']}
color14 {tokens['color14']}
color7  {tokens['color7']}
color15 {tokens['color15']}
"""
safe_write("~/.config/kitty/colors.conf", kitty_conf)

# Render Alacritty
alacritty_toml = f"""[colors.primary]
background = "{tokens['background']}"
foreground = "{tokens['foreground']}"

[colors.normal]
black   = "{tokens['color0']}"
red     = "{tokens['color1']}"
green   = "{tokens['color2']}"
yellow  = "{tokens['color3']}"
blue    = "{tokens['color4']}"
magenta = "{tokens['color5']}"
cyan    = "{tokens['color6']}"
white   = "{tokens['color7']}"

[colors.bright]
black   = "{tokens['color8']}"
red     = "{tokens['color9']}"
green   = "{tokens['color10']}"
yellow  = "{tokens['color11']}"
blue    = "{tokens['color12']}"
magenta = "{tokens['color13']}"
cyan    = "{tokens['color14']}"
white   = "{tokens['color15']}"
"""
safe_write("~/.config/alacritty/colors.toml", alacritty_toml)

# Render Rofi
rofi_rasi = f"""* {{
    background:     {tokens['background']};
    background-alt: {tokens['color8']};
    foreground:     {tokens['foreground']};
    selected:       {tokens['color4']};
    border:         {tokens['color12']};
    active:         {tokens['color2']};
    urgent:         {tokens['color1']};
}}
"""
safe_write("~/.config/rofi/colors/wallust.rasi", rofi_rasi)

# Render Polybar
polybar_ini = f"""[color]
BACKGROUND = {tokens['background']}
FOREGROUND = {tokens['foreground']}
ALTBACKGROUND = {tokens['color8']}
ALTFOREGROUND = {tokens['color7']}
ACCENT = {tokens['color4']}
PRIMARY = {tokens['color4']}
SECONDARY = {tokens['color5']}
SUCCESS = {tokens['color2']}
WARNING = {tokens['color3']}
DANGER = {tokens['color1']}
"""
safe_write("~/.config/polybar/colors.ini", polybar_ini)

# Render Dunst
dunstrc = f"""[global]
monitor = 0
follow = keyboard
origin = top-center
offset = (0, 36)
width = (300, 500)
height = (100, 300)
gap_size = 8
padding = 12
horizontal_padding = 16
text_icon_padding = 12
corner_radius = 8
frame_width = 2
separator_height = 2

font = JetBrainsMono Nerd Font 10
line_height = 0
alignment = left
indicate_hidden = yes
stack_duplicates = true
hide_duplicate_count = false
always_run_script = true
markup = full
format = "<b>%a</b>\n%s\n%b"
word_wrap = yes
ellipsize = middle
ignore_newline = no

icon_position = left
max_icon_size = 48
enable_recursive_icon_lookup = true

frame_color = "{tokens['color4']}"
separator_color = "{tokens['color8']}"

[urgency_low]
timeout = 4
background = "{tokens['background']}"
foreground = "{tokens['foreground']}"
frame_color = "{tokens['color8']}"

[urgency_normal]
timeout = 6
background = "{tokens['background']}"
foreground = "{tokens['foreground']}"
frame_color = "{tokens['color4']}"

[urgency_critical]
timeout = 0
background = "{tokens['background']}"
foreground = "{tokens['foreground']}"
frame_color = "{tokens['color1']}"
"""
safe_write("~/.config/dunst/dunstrc", dunstrc)

# Render GTK CSS
gtk_css = f"""@define-color theme_bg_color {tokens['background']};
@define-color theme_fg_color {tokens['foreground']};
@define-color theme_selected_bg_color {tokens['color4']};
@define-color theme_selected_fg_color {tokens['background']};
@define-color theme_border_color {tokens['color8']};
"""
safe_write("~/.config/gtk-3.0/colors.css", gtk_css)
safe_write("~/.config/gtk-4.0/colors.css", gtk_css)

print("[SUCCESS] All Wallust color templates rendered from Pywal!")
