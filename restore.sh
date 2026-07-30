#!/bin/bash
# ==============================================================================
# RESTORE SCRIPT - Archcraft Dotfiles & Configuration Symlinker
# ==============================================================================
# Safely symlinks configurations from ~/dotfiles into the home directory (~/),
# creating timestamped backups of any pre-existing files or directories.
# ==============================================================================

set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${HOME}/.dotfiles_backup_${BACKUP_TIMESTAMP}"

log_info() { echo -e "\e[34m[INFO]\e[0m $*"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $*"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $*"; }

log_info "Starting configuration restoration..."
log_info "Dotfiles source: ${DOTFILES_DIR}"

mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/Pictures"

backup_and_symlink() {
    local src="$1"
    local dest="$2"

    if [ ! -e "${src}" ]; then
        return 0
    fi

    # Check if dest is already symlinked correctly
    if [ -L "${dest}" ] && [ "$(readlink -f "${dest}")" = "$(readlink -f "${src}")" ]; then
        log_info "Already correctly symlinked: ${dest}"
        return 0
    fi

    # Backup existing destination file or directory
    if [ -e "${dest}" ] || [ -L "${dest}" ]; then
        mkdir -p "${BACKUP_DIR}/$(dirname "${dest#${HOME}/}")"
        log_warn "Backing up existing ${dest} to ${BACKUP_DIR}"
        mv "${dest}" "${BACKUP_DIR}/"
    fi

    mkdir -p "$(dirname "${dest}")"
    ln -s "${src}" "${dest}"
    log_success "Symlinked: ${dest} -> ${src}"
}

# ------------------------------------------------------------------------------
# 1. SYMLINK ~/.config DIRECTORIES & FILES
# ------------------------------------------------------------------------------
log_info "Restoring ~/.config files..."

if [ -d "${DOTFILES_DIR}/config" ]; then
    for item in "${DOTFILES_DIR}/config"/*; do
        if [ -e "${item}" ]; then
            base_name="$(basename "${item}")"
            if [ "${base_name}" = "Cursor" ]; then
                mkdir -p "${HOME}/.config/Cursor"
                if [ -d "${DOTFILES_DIR}/config/Cursor/User" ]; then
                    backup_and_symlink "${DOTFILES_DIR}/config/Cursor/User" "${HOME}/.config/Cursor/User"
                fi
            else
                backup_and_symlink "${item}" "${HOME}/.config/${base_name}"
            fi
        fi
    done
fi

# ------------------------------------------------------------------------------
# 2. SYMLINK HOME DOTFILES
# ------------------------------------------------------------------------------
log_info "Restoring home dotfiles..."

if [ -d "${DOTFILES_DIR}/home" ]; then
    for item in "${DOTFILES_DIR}/home"/.*; do
        base_name="$(basename "${item}")"
        if [ "${base_name}" != "." ] && [ "${base_name}" != ".." ] && [ "${base_name}" != ".git" ]; then
            backup_and_symlink "${item}" "${HOME}/${base_name}"
        fi
    done

    if [ -d "${DOTFILES_DIR}/home/Pictures/wallpapers" ]; then
        backup_and_symlink "${DOTFILES_DIR}/home/Pictures/wallpapers" "${HOME}/Pictures/wallpapers"
    fi
fi

# ------------------------------------------------------------------------------
# 3. SYMLINK LOCAL BIN SCRIPTS
# ------------------------------------------------------------------------------
log_info "Restoring custom binaries (~/.local/bin)..."

if [ -d "${DOTFILES_DIR}/local_bin" ]; then
    for item in "${DOTFILES_DIR}/local_bin"/*; do
        if [ -f "${item}" ]; then
            base_name="$(basename "${item}")"
            backup_and_symlink "${item}" "${HOME}/.local/bin/${base_name}"
        fi
    done
fi

# Dynamically resolve any ${HOME} placeholders to current user HOME
for cfg_file in "${HOME}/.config/nitrogen/bg-saved.cfg" "${HOME}/.config/nitrogen/nitrogen.cfg" "${HOME}/.config/gtk-3.0/bookmarks"; do
    if [ -f "${cfg_file}" ]; then
        sed -i "s|\${HOME}|${HOME}|g" "${cfg_file}" 2>/dev/null || true
    fi
done

if [ -d "${BACKUP_DIR}" ]; then
    log_warn "Pre-existing files backed up to: ${BACKUP_DIR}"
fi

log_success "Restoration completed successfully!"
