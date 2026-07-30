#!/bin/bash
# ==============================================================================
# BACKUP SCRIPT - Archcraft System & Dotfiles Exporter
# ==============================================================================
# This script exports system package manifests, enabled services, GTK/QT settings,
# Openbox configurations, AutoKey remappings, shell dotfiles, wallpapers, and
# user binaries from the current live system into the ~/dotfiles repository.
# ==============================================================================

set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLISTS_DIR="${DOTFILES_DIR}/pkglists"
CONFIG_DIR="${DOTFILES_DIR}/config"
HOME_DIR="${DOTFILES_DIR}/home"
SYSTEM_DIR="${DOTFILES_DIR}/system"
BIN_DIR="${DOTFILES_DIR}/local_bin"

log_info() { echo -e "\e[34m[INFO]\e[0m $*"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $*"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $*"; }

log_info "Starting Archcraft System Configuration Backup..."

mkdir -p "${PKGLISTS_DIR}" "${CONFIG_DIR}" "${HOME_DIR}" "${SYSTEM_DIR}" "${BIN_DIR}" "${HOME_DIR}/Pictures"

# ------------------------------------------------------------------------------
# 1. EXPORT PACKAGE LISTS
# ------------------------------------------------------------------------------
log_info "Exporting package manifests..."

if command -v pacman &>/dev/null; then
    pacman -Qqe | grep -v "$(pacman -Qqm)" > "${PKGLISTS_DIR}/pkglist_official.txt" || true
    pacman -Qqm > "${PKGLISTS_DIR}/pkglist_aur.txt" || true
fi

# Ensure discord and cursor-bin are included
if ! grep -q "^discord$" "${PKGLISTS_DIR}/pkglist_official.txt" 2>/dev/null; then
    echo "discord" >> "${PKGLISTS_DIR}/pkglist_official.txt"
    sort -u "${PKGLISTS_DIR}/pkglist_official.txt" -o "${PKGLISTS_DIR}/pkglist_official.txt"
fi

if ! grep -q "^cursor-bin$" "${PKGLISTS_DIR}/pkglist_aur.txt" 2>/dev/null; then
    echo "cursor-bin" >> "${PKGLISTS_DIR}/pkglist_aur.txt"
    sort -u "${PKGLISTS_DIR}/pkglist_aur.txt" -o "${PKGLISTS_DIR}/pkglist_aur.txt"
fi

if command -v flatpak &>/dev/null; then
    flatpak list --app --columns=application > "${PKGLISTS_DIR}/pkglist_flatpak.txt" || true
fi

if command -v npm &>/dev/null; then
    npm list -g --depth=0 --json | grep '"' | head -n -1 > "${PKGLISTS_DIR}/pkglist_npm.txt" 2>/dev/null || true
fi

if command -v uv &>/dev/null; then
    uv tool list > "${PKGLISTS_DIR}/pkglist_uv.txt" 2>/dev/null || true
fi

log_success "Package manifests saved to ${PKGLISTS_DIR}"

# ------------------------------------------------------------------------------
# 2. EXPORT SYSTEMD SERVICES
# ------------------------------------------------------------------------------
log_info "Exporting systemd enabled services..."

systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > "${SYSTEM_DIR}/system_services.txt" || true
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > "${SYSTEM_DIR}/user_services.txt" || true

log_success "Enabled services saved to ${SYSTEM_DIR}"

# ------------------------------------------------------------------------------
# 3. EXPORT USER CONFIGURATIONS (~/.config)
# ------------------------------------------------------------------------------
log_info "Exporting ~/.config directories..."

CONFIG_ITEMS=(
    "alacritty"
    "autokey"
    "dunst"
    "fastfetch"
    "fish"
    "geany"
    "gtk-2.0"
    "gtk-3.0"
    "gtk-4.0"
    "kitty"
    "Kvantum"
    "Linux Wallpaper Engine"
    "linux-wallpaperengine-gui"
    "nitrogen"
    "obmenu-generator"
    "openbox"
    "picom.conf"
    "picom-ibhagwan.conf"
    "picom-jonaburg.conf"
    "picom-original.conf"
    "plank"
    "qt5ct"
    "qt6ct"
    "ranger"
    "rofi"
    "starship.toml"
    "mimeapps.list"
    "user-dirs.dirs"
)

# Export Cursor Editor User settings specifically
if [ -d "${HOME}/.config/Cursor/User" ]; then
    mkdir -p "${CONFIG_DIR}/Cursor/User"
    [ -f "${HOME}/.config/Cursor/User/settings.json" ] && cp -a "${HOME}/.config/Cursor/User/settings.json" "${CONFIG_DIR}/Cursor/User/"
    [ -f "${HOME}/.config/Cursor/User/keybindings.json" ] && cp -a "${HOME}/.config/Cursor/User/keybindings.json" "${CONFIG_DIR}/Cursor/User/"
    [ -d "${HOME}/.config/Cursor/User/snippets" ] && cp -a "${HOME}/.config/Cursor/User/snippets" "${CONFIG_DIR}/Cursor/User/"
    log_info "  -> Backed up ~/.config/Cursor/User settings and keymaps"
fi

# Export Essential Brave Browser Profile (Sessions, Open Tabs, Extensions, History, Preferences)
if [ -d "${HOME}/.config/BraveSoftware" ]; then
    mkdir -p "${CONFIG_DIR}/BraveSoftware/Brave-Browser/Default"
    [ -f "${HOME}/.config/BraveSoftware/Brave-Browser/Local State" ] && cp -a "${HOME}/.config/BraveSoftware/Brave-Browser/Local State" "${CONFIG_DIR}/BraveSoftware/Brave-Browser/"
    BRAVE_ESSENTIALS=("Sessions" "Preferences" "Secure Preferences" "Bookmarks" "History" "Extensions" "Extension Rules" "Extension State")
    for item in "${BRAVE_ESSENTIALS[@]}"; do
        src="${HOME}/.config/BraveSoftware/Brave-Browser/Default/${item}"
        dest="${CONFIG_DIR}/BraveSoftware/Brave-Browser/Default/${item}"
        if [ -e "${src}" ]; then
            if ! ([ -L "${src}" ] && [ "$(readlink -f "${src}")" = "$(readlink -f "${dest}")" ]); then
                rm -rf "${dest}"
                cp -a "${src}" "${CONFIG_DIR}/BraveSoftware/Brave-Browser/Default/"
            fi
        fi
    done
    log_info "  -> Backed up Brave browser session state, open tabs, and preferences"
fi

for item in "${CONFIG_ITEMS[@]}"; do
    src="${HOME}/.config/${item}"
    dest="${CONFIG_DIR}/${item}"
    if [ -e "${src}" ]; then
        if [ -L "${src}" ] && [ "$(readlink -f "${src}")" = "$(readlink -f "${dest}")" ]; then
            log_info "  -> Already linked into dotfiles: ~/.config/${item}"
            continue
        fi
        rm -rf "${dest}"
        cp -a "${src}" "${CONFIG_DIR}/"
        log_info "  -> Backed up ~/.config/${item}"
    fi
done

log_success "Configuration directories exported."

# ------------------------------------------------------------------------------
# 4. EXPORT HOME DOTFILES & WALLPAPERS
# ------------------------------------------------------------------------------
log_info "Exporting home dotfiles and wallpapers..."

HOME_ITEMS=(
    ".zshrc"
    ".bashrc"
    ".gitconfig"
    ".xprofile"
    ".gtkrc-2.0"
)

for item in "${HOME_ITEMS[@]}"; do
    src="${HOME}/${item}"
    dest="${HOME_DIR}/${item}"
    if [ -f "${src}" ]; then
        if [ -L "${src}" ] && [ "$(readlink -f "${src}")" = "$(readlink -f "${dest}")" ]; then
            log_info "  -> Already linked into dotfiles: ~/${item}"
            continue
        fi
        cp -a "${src}" "${HOME_DIR}/"
        log_info "  -> Backed up ~/${item}"
    fi
done

if [ -d "${HOME}/Pictures/wallpapers" ]; then
    src="${HOME}/Pictures/wallpapers"
    dest="${HOME_DIR}/Pictures/wallpapers"
    if ! ([ -L "${src}" ] && [ "$(readlink -f "${src}")" = "$(readlink -f "${dest}")" ]); then
        rm -rf "${HOME_DIR}/Pictures/wallpapers"
        cp -a "${src}" "${HOME_DIR}/Pictures/"
        log_info "  -> Backed up wallpapers directory (~/Pictures/wallpapers)"
    else
        log_info "  -> Already linked into dotfiles: ~/Pictures/wallpapers"
    fi
fi

# ------------------------------------------------------------------------------
# 5. EXPORT LOCAL BIN SCRIPTS (~/.local/bin)
# ------------------------------------------------------------------------------
log_info "Exporting custom user scripts..."

if [ -d "${HOME}/.local/bin" ]; then
    mkdir -p "${BIN_DIR}"
    find "${HOME}/.local/bin" -maxdepth 1 -type f -not -name "agy*" -not -name "env*" -exec cp -a {} "${BIN_DIR}/" \; 2>/dev/null || true
    log_info "  -> Backed up ~/.local/bin custom scripts"
fi

log_success "Backup completed successfully!"
log_info "Run 'git status' inside ${DOTFILES_DIR} to view exported changes."
