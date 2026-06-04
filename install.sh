#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BREW_BIN=""
SUDO_KEEPALIVE_PID=""
SUDO_WARMED=0
PASSWORD_CASKS=(zulu@11 zulu@8)
MAS_APP_IDS=(1503446680 1451685025)
MAS_APP_NAMES=(PastePal WireGuard)

say() {
  printf '%s\n' "$1"
}

cleanup() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

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

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
    return 0
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
    return 0
  fi

  return 1
}

install_homebrew() {
  if BREW_BIN="$(find_brew)"; then
    say "✅ Homebrew already installed."
  else
    say "🍺 Installing Homebrew..."
    warm_sudo
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    BREW_BIN="$(find_brew)"
  fi

  eval "$("$BREW_BIN" shellenv)"
  BREW_BIN="$(command -v brew)"
}

is_mas_app_installed() {
  local app_id="$1"

  mas list | awk '{print $1}' | grep -Fxq "$app_id"
}

install_mas_cli() {
  if command -v mas >/dev/null 2>&1; then
    return 0
  fi

  say "📲 Installing Mac App Store CLI..."
  "$BREW_BIN" install mas
}

warm_sudo() {
  if [[ "$SUDO_WARMED" -eq 1 ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    say "❌ Installing all dependencies requires sudo. Run ./install.sh from an interactive terminal so macOS can ask for your password once." >&2
    return 1
  else
    say "🔐 Refreshing sudo credentials for package installers..."
    sudo -k
    sudo -v
    SUDO_WARMED=1
  fi

  while true; do
    sudo -n -v >/dev/null 2>&1 || exit
    sleep 60
  done &
  SUDO_KEEPALIVE_PID="$!"
}

install_password_dependencies() {
  local missing_casks=()
  local missing_mas_ids=()
  local missing_mas_names=()
  local i

  for cask in "${PASSWORD_CASKS[@]}"; do
    if ! "$BREW_BIN" list --cask "$cask" >/dev/null 2>&1; then
      missing_casks+=("$cask")
    fi
  done

  install_mas_cli
  for i in "${!MAS_APP_IDS[@]}"; do
    if ! is_mas_app_installed "${MAS_APP_IDS[$i]}"; then
      missing_mas_ids+=("${MAS_APP_IDS[$i]}")
      missing_mas_names+=("${MAS_APP_NAMES[$i]}")
    fi
  done

  if [[ "${#missing_casks[@]}" -eq 0 && "${#missing_mas_ids[@]}" -eq 0 ]]; then
    return 0
  fi

  warm_sudo
  say "🔑 Installing password-gated dependencies first..."

  for i in "${!missing_mas_ids[@]}"; do
    say "📲 Installing ${missing_mas_names[$i]} from the Mac App Store..."
    mas install "${missing_mas_ids[$i]}"
  done

  if [[ "${#missing_casks[@]}" -gt 0 ]]; then
    say "☕ Installing privileged JDK casks..."
    "$BREW_BIN" install --cask "${missing_casks[@]}"
  fi
}

install_dependencies() {
  say "🍺 Homebrew"
  install_homebrew

  if "$BREW_BIN" bundle check --file "$DOTFILES_DIR/Brewfile"; then
    say "✅ Brewfile dependencies already installed."
    return 0
  fi

  install_password_dependencies
  say "📦 Installing Brewfile dependencies..."
  "$BREW_BIN" bundle install --file "$DOTFILES_DIR/Brewfile"
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

install_dependencies
say ""

say "🐚 Shell"
install_oh_my_zsh
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
"$DOTFILES_DIR/scripts/macos.sh"

say ""
say "👑 Dotfiles installed."
