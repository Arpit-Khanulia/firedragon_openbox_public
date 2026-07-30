#!/usr/bin/env bash
# ==============================================================================
# INSTALL SCRIPT - Recreate Archcraft System Environment
# ==============================================================================
# Automated, idempotent installer script that turns a clean Archcraft Linux
# installation into a exact replica of your customized environment.
# ==============================================================================

set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${DOTFILES_DIR}/install.log"

exec > >(tee -i "${LOG_FILE}")
exec 2>&1

log_info() { echo -e "\e[34m[INFO]\e[0m $*"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $*"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $*"; }

log_info "Starting Archcraft Environment Automated Installer..."
log_info "Log file location: ${LOG_FILE}"

# ------------------------------------------------------------------------------
# 1. PRE-FLIGHT SYSTEM CHECKS
# ------------------------------------------------------------------------------
log_info "Performing pre-flight checks..."

if [ ! -f /etc/os-release ]; then
    log_error "Cannot determine OS release. /etc/os-release missing."
    exit 1
fi

if ! grep -qiE 'arch|archcraft' /etc/os-release; then
    log_error "This installer is designed for Arch Linux / Archcraft systems only."
    exit 1
fi

if ! ping -c 1 8.8.8.8 &>/dev/null && ! curl -s --head https://archlinux.org &>/dev/null; then
    log_error "No active internet connection. Please connect to the internet before running."
    exit 1
fi

log_info "Requesting sudo privileges..."
sudo -v
# Keep-alive sudo timestamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

log_success "Pre-flight checks passed!"

# ------------------------------------------------------------------------------
# 2. BASE DEPENDENCIES & AUR HELPER (YAY)
# ------------------------------------------------------------------------------
log_info "Updating system package databases..."
sudo pacman -Sy --noconfirm

log_info "Installing base dependencies..."
sudo pacman -S --needed --noconfirm base-devel git curl wget rsync wmctrl xdotool

if ! command -v yay &>/dev/null; then
    log_info "Installing 'yay' AUR helper..."
    BUILD_DIR="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "${BUILD_DIR}/yay-bin"
    (cd "${BUILD_DIR}/yay-bin" && makepkg -si --noconfirm)
    rm -rf "${BUILD_DIR}"
    log_success "yay installed successfully!"
else
    log_info "AUR helper 'yay' is already installed."
fi

# ------------------------------------------------------------------------------
# 3. OFFICIAL PACKAGES INSTALLATION
# ------------------------------------------------------------------------------
PKGLIST_OFFICIAL="${DOTFILES_DIR}/pkglists/pkglist_official.txt"
if [ -f "${PKGLIST_OFFICIAL}" ]; then
    log_info "Installing official repository packages from list..."
    mapfile -t OFFICIAL_PKGS < <(grep -v '^#' "${PKGLIST_OFFICIAL}" | grep -v '^$')
    if [ ${#OFFICIAL_PKGS[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}" || log_warn "Some official packages failed to install."
        log_success "Official packages installation finished."
    fi
fi

# ------------------------------------------------------------------------------
# 4. AUR PACKAGES INSTALLATION
# ------------------------------------------------------------------------------
PKGLIST_AUR="${DOTFILES_DIR}/pkglists/pkglist_aur.txt"
if [ -f "${PKGLIST_AUR}" ]; then
    log_info "Installing AUR packages from list..."
    mapfile -t AUR_PKGS < <(grep -v '^#' "${PKGLIST_AUR}" | grep -v '^$')
    if [ ${#AUR_PKGS[@]} -gt 0 ]; then
        yay -S --needed --noconfirm "${AUR_PKGS[@]}" || log_warn "Some AUR packages failed to install."
        log_success "AUR packages installation finished."
    fi
fi

# ------------------------------------------------------------------------------
# 5. FLATPAK PACKAGES INSTALLATION
# ------------------------------------------------------------------------------
PKGLIST_FLATPAK="${DOTFILES_DIR}/pkglists/pkglist_flatpak.txt"
if [ -f "${PKGLIST_FLATPAK}" ] && command -v flatpak &>/dev/null; then
    log_info "Installing Flatpak packages..."
    while IFS= read -r app; do
        if [ -n "${app}" ]; then
            flatpak install -y flathub "${app}" || true
        fi
    done < "${PKGLIST_FLATPAK}"
fi

# ------------------------------------------------------------------------------
# 6. CONFIGURATION RESTORATION (SYMLINKS & WALLPAPERS)
# ------------------------------------------------------------------------------
log_info "Restoring configurations, dotfiles, and wallpapers..."
"${DOTFILES_DIR}/restore.sh"

# ------------------------------------------------------------------------------
# 7. ENABLE SYSTEMD SERVICES
# ------------------------------------------------------------------------------
log_info "Enabling systemd system services..."
SYSTEM_SERVICES_FILE="${DOTFILES_DIR}/system/system_services.txt"
if [ -f "${SYSTEM_SERVICES_FILE}" ]; then
    while IFS= read -r service; do
        if [ -n "${service}" ] && systemctl list-unit-files "${service}" &>/dev/null; then
            sudo systemctl enable "${service}" 2>/dev/null || log_warn "Failed to enable service: ${service}"
        fi
    done < "${SYSTEM_SERVICES_FILE}"
fi

log_info "Enabling systemd user services..."
USER_SERVICES_FILE="${DOTFILES_DIR}/system/user_services.txt"
if [ -f "${USER_SERVICES_FILE}" ]; then
    while IFS= read -r service; do
        if [ -n "${service}" ]; then
            systemctl --user enable "${service}" 2>/dev/null || log_warn "Failed to enable user service: ${service}"
        fi
    done < "${USER_SERVICES_FILE}"
fi

# ------------------------------------------------------------------------------
# 8. DEFAULT SHELL CONFIGURATION
# ------------------------------------------------------------------------------
if command -v zsh &>/dev/null && [ "${SHELL}" != "$(which zsh)" ]; then
    log_info "Setting default shell to Zsh..."
    sudo chsh -s "$(which zsh)" "${USER}" || log_warn "Could not set default shell to zsh."
fi

# ------------------------------------------------------------------------------
# 9. FINISH & REBOOT PROMPT
# ------------------------------------------------------------------------------
log_success "=========================================================================="
log_success "Archcraft Environment Installation Complete!"
log_success "All dotfiles, custom scripts, AutoKey mappings, and packages are restored."
log_success "Please reboot your system to apply all desktop and service configurations."
log_success "=========================================================================="
