#!/usr/bin/env bash
set -euo pipefail

# Bootstrap macOS or Linux from the dotfiles repo.
#
# High-level flow:
#   1. Detect the OS and pull the latest repo changes when it is safe to do so.
#   2. Run install modules in order. Each module lives in
#      scripts/<os>/<module>.sh with a shared fallback in
#      scripts/common/<module>.sh; modules without a variant for the current
#      OS are skipped.
#
# The script is intended to be idempotent. Existing files that would be
# replaced by symlinks are moved into ~/.dotfiles-backup/<timestamp>/.
# Some package installers require sudo, so run this from an interactive
# terminal on a fresh machine.
#
# Set DOTFILES_DRY_RUN=1 to print the module plan without executing anything.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$DOTFILES_DIR/scripts/lib.sh"

OS="$(detect_os)"
export DOTFILES_BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

# Ordered install modules. Resolution per module:
#   scripts/$OS/<module>.sh  -> OS-specific variant
#   scripts/common/<module>.sh -> shared fallback
#   neither  -> skipped
MODULES=(
  "packages"
  "android-sdk"
  "shell"
  "git"
  "tools"
  "preferences"
  "ai-skills"
  "defaults"
  "desktop-apps"
)

# Pull only when the working tree is clean. Local edits are treated as user
# work and are never overwritten by the installer. Skipped entirely in dry-run
# mode so a dry run has no side effects.
auto_pull() {
  if [[ -n "${DOTFILES_DRY_RUN:-}" ]]; then
    return 0
  fi

  if ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    say "ℹ️  Not a Git repo, skipping auto-pull."
    return 0
  fi

  if ! git -C "$DOTFILES_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    say "ℹ️  No upstream branch configured, skipping auto-pull."
    return 0
  fi

  if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
    say "⚠️  Local changes found, skipping auto-pull."
    return 0
  fi

  say "⬇️  Pulling latest dotfiles..."
  if ! git -C "$DOTFILES_DIR" pull --ff-only; then
    say "⚠️  Cannot fast-forward, skipping auto-pull."
  fi
}

module_script() {
  local module="$1"
  local os_script="$DOTFILES_DIR/scripts/$OS/$module.sh"
  local common_script="$DOTFILES_DIR/scripts/common/$module.sh"

  if [[ -f "$os_script" ]]; then
    printf '%s\n' "$os_script"
  elif [[ -f "$common_script" ]]; then
    printf '%s\n' "$common_script"
  else
    return 1
  fi
}

say "✨ Dotfiles setup ($OS)"
say "📍 Source: $DOTFILES_DIR"
say ""

auto_pull
say ""

for module in "${MODULES[@]}"; do
  if [[ " ${DOTFILES_SKIP_MODULES:-} " == *" $module "* ]]; then
    say "⏭️  Skipping $module (DOTFILES_SKIP_MODULES)."
    say ""
    continue
  fi

  if ! script="$(module_script "$module")"; then
    say "⏭️  Skipping $module (not available for $OS)."
    say ""
    continue
  fi

  say "▶️  $module"
  if [[ -n "${DOTFILES_DRY_RUN:-}" ]]; then
    say "   (dry run) $script"
    say ""
    continue
  fi

  bash "$script"
  say ""
done

if [[ -n "${DOTFILES_DRY_RUN:-}" ]]; then
  say "👑 Dotfiles install planned (dry run)."
else
  say "👑 Dotfiles installed."
fi
