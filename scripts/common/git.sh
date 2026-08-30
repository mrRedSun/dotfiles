#!/usr/bin/env bash
set -euo pipefail

# Link the repo-managed git configs into $HOME.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🌿 Git"

link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/.gitignore" "$HOME/.gitignore"

say "✅ Git configured."
