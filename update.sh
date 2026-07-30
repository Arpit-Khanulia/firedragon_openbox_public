#!/usr/bin/env bash
# ==============================================================================
# UPDATE SCRIPT - Archcraft Dotfiles Sync & Git Committer
# ==============================================================================
# Synchronizes current system configurations back into the dotfiles repo
# and commits/pushes updates to GitHub.
# ==============================================================================

set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() { echo -e "\e[34m[INFO]\e[0m $*"; }
log_success() { echo -e "\e[32m[SUCCESS]\e[0m $*"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $*"; }

log_info "Synchronizing live system configurations into dotfiles repository..."

# Run backup script to pull latest state
"${DOTFILES_DIR}/backup.sh"

cd "${DOTFILES_DIR}"

if [ -z "$(git status --porcelain)" ]; then
    log_success "No changes detected in dotfiles configuration. Repository is up-to-date."
    exit 0
fi

log_info "Changes detected:"
git status -s

COMMIT_MSG="${1:-Update dotfiles configuration: $(date +'%Y-%m-%d %H:%M:%S')}"

log_info "Staging and committing changes..."
git add .
git commit -m "${COMMIT_MSG}"
log_success "Committed with message: '${COMMIT_MSG}'"

if git remote get-url origin &>/dev/null; then
    log_info "Pushing updates to remote repository..."
    if git push origin master 2>/dev/null || git push origin main 2>/dev/null || git push; then
        log_success "Successfully pushed dotfiles updates to remote!"
    else
        log_warn "Failed to push automatically. Please check your internet connection or git credentials."
    fi
fi
