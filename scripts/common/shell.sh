#!/usr/bin/env bash
set -euo pipefail

# Install Oh My Zsh, its custom plugins, and the repo-managed zsh configs.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🐚 Shell"

# Oh My Zsh's official installer is interactive, so this clones the framework
# directly. If ~/.oh-my-zsh partially exists, merge the framework into it while
# preserving any existing custom plugins.
install_oh_my_zsh() {
  if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    say "✅ Oh My Zsh already installed."
    return 0
  fi

  say "🎨 Installing Oh My Zsh..."
  if [[ -e "$HOME/.oh-my-zsh" ]]; then
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$tmp_dir/oh-my-zsh"
    mkdir -p "$HOME/.oh-my-zsh"
    cp -R "$tmp_dir/oh-my-zsh"/. "$HOME/.oh-my-zsh/"
    rm -rf "$tmp_dir"
    return 0
  fi

  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}

# Clone the custom plugins referenced by .zshrc into the Oh My Zsh custom
# directory. Each plugin is skipped when its checkout already exists.
install_omz_custom_plugins() {
  local plugin_dir="$HOME/.oh-my-zsh/custom/plugins"

  install_custom_plugin() {
    local name="$1"
    local repo="$2"

    if [[ -d "$plugin_dir/$name" ]]; then
      return 0
    fi

    say "🔌 Installing Oh My Zsh plugin: $name"
    git clone --depth 1 "$repo" "$plugin_dir/$name"
  }

  install_custom_plugin zsh-vi-mode https://github.com/jeffreytse/zsh-vi-mode.git
  install_custom_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
  install_custom_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
}

install_oh_my_zsh
install_omz_custom_plugins

link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

if [[ ! -e "$HOME/.zshrc.local" ]]; then
  touch "$HOME/.zshrc.local"
  say "📝 Created ~/.zshrc.local for machine-local overrides."
fi

say "✅ Shell configured."
