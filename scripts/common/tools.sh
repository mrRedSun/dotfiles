#!/usr/bin/env bash
set -euo pipefail

# Link the cross-platform tool configs (Neovim, tmux) into $HOME.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🛠️ Tools"

link_file "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.config/tmux/.tmux.conf"

say "✅ Tools configured."
