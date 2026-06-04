#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

say() {
  printf '%s\n' "$1"
}

auto_pull() {
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
  git -C "$DOTFILES_DIR" pull --ff-only
}

link_file() {
  local source_path="$1"
  local target_path="$2"

  if [[ ! -e "$source_path" ]]; then
    say "❌ Missing source: $source_path" >&2
    return 1
  fi

  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_path" ]]; then
    say "✅ Already linked: $target_path"
    return 0
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target_path" "$BACKUP_DIR/"
    say "📦 Backed up: $target_path -> $BACKUP_DIR/"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  say "🔗 Linked: $target_path -> $source_path"
}

say "✨ Dotfiles setup"
say "📍 Source: $DOTFILES_DIR"
say ""

auto_pull
say ""

say "🐚 Shell"
link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

say ""
say "🌿 Git"
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/.gitignore" "$HOME/.gitignore"
link_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

say ""
say "🛠️ Tools"
link_file "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.config/tmux/.tmux.conf"
link_file "$DOTFILES_DIR/config/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
link_file "$DOTFILES_DIR/config/karabiner" "$HOME/.config/karabiner"
link_file "$DOTFILES_DIR/config/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

say ""
say "👑 Dotfiles installed."
