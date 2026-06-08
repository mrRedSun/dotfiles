#!/usr/bin/env bash
set -euo pipefail

# Bootstrap this Mac from the dotfiles repo.
#
# High-level flow:
#   1. Pull the latest repo changes when it is safe to do so.
#   2. Install Homebrew and every Brewfile dependency.
#   3. Install Android SDK packages and create a ready-to-run emulator.
#   4. Install Oh My Zsh and link repo-managed dotfiles into $HOME.
#   5. Restore app preferences with Mackup copy mode.
#   6. Apply macOS defaults from scripts/macos.sh.
#   7. Launch desktop apps once so first-run prompts surface immediately.
#
# The script is intended to be idempotent. Existing files that would be
# replaced by symlinks are moved into ~/.dotfiles-backup/<timestamp>/.
# Some package installers require sudo or Mac App Store auth, so run this from
# an interactive terminal on a fresh machine.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BREW_BIN=""
SUDO_KEEPALIVE_PID=""
SUDO_WARMED=0

# Casks in this list use pkg installers or system extensions. They are handled
# before the main Brewfile pass so password prompts are grouped together.
PASSWORD_CASKS=(karabiner-elements zulu@11 zulu@8)

# Mac App Store apps managed by mas. Keep IDs and names aligned by index.
MAS_APP_IDS=(1503446680 1451685025)
MAS_APP_NAMES=(PastePal WireGuard)

# Android SDK packages installed after android-commandlinetools is available.
# Homebrew installs the SDK manager; sdkmanager installs the emulator payloads.
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
ANDROID_SDK_PACKAGES=(
  "cmdline-tools;latest"
  "emulator"
  "platform-tools"
  "platforms;android-35"
  "build-tools;35.0.0"
  "system-images;android-35;google_apis_playstore;arm64-v8a"
)
ANDROID_AVD_NAME="Pixel_9_API_35"
ANDROID_AVD_DEVICE="pixel_9"
ANDROID_AVD_PACKAGE="system-images;android-35;google_apis_playstore;arm64-v8a"

# GUI apps to open after setup. This helps macOS show any first-run permission,
# login, or background-item prompts while setup is still fresh in memory.
DESKTOP_APPS=(
  "AeroSpace"
  "AlDente"
  "Android Studio"
  "Arc"
  "ChatGPT"
  "Codex"
  "Fork"
  "iTerm"
  "Karabiner-Elements"
  "KeyCastr"
  "Macs Fan Control"
  "Obsidian"
  "OrbStack"
  "PastePal"
  "Postman"
  "Raycast"
  "Rectangle Pro"
  "SwiftFormat for Xcode"
  "TickTick"
  "Visual Studio Code"
  "WireGuard"
  "Xcodes"
)

say() {
  printf '%s\n' "$1"
}

cleanup() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

# Pull only when the working tree is clean. Local edits are treated as user
# work and are never overwritten by the installer.
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

# Homebrew may not be in PATH yet on a fresh Apple Silicon install. Check the
# canonical install locations before deciding it needs to be installed.
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

# Ensure Homebrew exists and update this process PATH using brew shellenv.
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

# Homebrew can record pkg casks as installed even when the privileged pkg
# payload did not finish. Karabiner is checked by its real installed artifact.
needs_password_cask_install() {
  local cask="$1"

  case "$cask" in
    karabiner-elements)
      [[ ! -x "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli" ]]
      ;;
    *)
      ! "$BREW_BIN" list --cask "$cask" >/dev/null 2>&1
      ;;
  esac
}

# Ask for sudo once and keep the ticket warm while long downloads/installers run.
# Non-interactive runs fail early so they do not half-install privileged casks.
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

# Install the small set of dependencies known to ask for passwords before the
# main Brewfile pass. This keeps prompts close together and makes repeats clean.
install_password_dependencies() {
  local missing_casks=()
  local missing_mas_ids=()
  local missing_mas_names=()
  local cask_action
  local i

  for cask in "${PASSWORD_CASKS[@]}"; do
    if needs_password_cask_install "$cask"; then
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
    say "☕ Installing privileged casks..."
    for cask in "${missing_casks[@]}"; do
      cask_action=install
      if "$BREW_BIN" list --cask "$cask" >/dev/null 2>&1; then
        cask_action=reinstall
      fi

      "$BREW_BIN" "$cask_action" --cask "$cask"
    done
  fi
}

# Install every Brewfile item. The password-gated pass runs first because
# brew bundle check alone is not enough for pkg casks like Karabiner.
install_dependencies() {
  say "🍺 Homebrew"
  install_homebrew

  install_password_dependencies

  if "$BREW_BIN" bundle check --file "$DOTFILES_DIR/Brewfile"; then
    say "✅ Brewfile dependencies already installed."
    return 0
  fi

  say "📦 Installing Brewfile dependencies..."
  "$BREW_BIN" bundle install --file "$DOTFILES_DIR/Brewfile"
}

# Install SDK packages that Homebrew does not manage directly, accept Android
# SDK licenses, and create a default Apple-Silicon-friendly Pixel emulator.
install_android_sdk() {
  local sdkmanager_bin
  local avdmanager_bin

  sdkmanager_bin="$(command -v sdkmanager || true)"
  if [[ -z "$sdkmanager_bin" && -x /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager ]]; then
    sdkmanager_bin=/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager
  fi

  if [[ -z "$sdkmanager_bin" ]]; then
    say "⚠️  sdkmanager not found; skipping Android SDK package install."
    return 0
  fi

  say "🤖 Installing Android SDK packages..."
  mkdir -p "$ANDROID_SDK_ROOT"
  yes | env JAVA_HOME=/opt/homebrew/opt/openjdk@17 PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" \
    "$sdkmanager_bin" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null
  env JAVA_HOME=/opt/homebrew/opt/openjdk@17 PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" \
    "$sdkmanager_bin" --sdk_root="$ANDROID_SDK_ROOT" "${ANDROID_SDK_PACKAGES[@]}"

  avdmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager"
  if [[ ! -x "$avdmanager_bin" ]]; then
    avdmanager_bin="$(dirname "$sdkmanager_bin")/avdmanager"
  fi
  if [[ -x "$avdmanager_bin" ]] && ! env ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" JAVA_HOME=/opt/homebrew/opt/openjdk@17 PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" \
    "$avdmanager_bin" list avd | grep -Fq "Name: $ANDROID_AVD_NAME"; then
    say "📱 Creating Android emulator: $ANDROID_AVD_NAME"
    echo "no" | env ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" JAVA_HOME=/opt/homebrew/opt/openjdk@17 PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" \
      "$avdmanager_bin" create avd --name "$ANDROID_AVD_NAME" --package "$ANDROID_AVD_PACKAGE" --device "$ANDROID_AVD_DEVICE"
  fi
}

# Symlink a repo file/directory into place. Existing user files are backed up
# instead of overwritten.
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

# Restore app plist/config files that Mackup knows how to manage. This uses
# Mackup copy mode, not link mode; Mackup warns that symlinked preferences are
# broken on modern macOS.
restore_mackup_configs() {
  local mackup_config="$DOTFILES_DIR/config/mackup.cfg"

  if ! command -v mackup >/dev/null 2>&1; then
    say "⚠️  Mackup not found; skipping app preference restore."
    return 0
  fi

  if [[ ! -f "$mackup_config" ]]; then
    say "⚠️  Missing Mackup config: $mackup_config"
    return 0
  fi

  say "📦 Restoring app preferences with Mackup..."
  mackup --config-file "$mackup_config" restore --force
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false
  defaults delete com.googlecode.iterm2 PrefsCustomFolder >/dev/null 2>&1 || true
  killall cfprefsd >/dev/null 2>&1 || true
}

# Open GUI apps without stealing focus. Failures are reported but do not stop
# setup, because some apps may require post-install approval before they launch.
launch_desktop_apps() {
  local app

  say "🚀 Launching desktop apps..."
  for app in "${DESKTOP_APPS[@]}"; do
    if open -gj -a "$app" >/dev/null 2>&1; then
      say "✅ Launched: $app"
    else
      say "⚠️  Could not launch: $app"
    fi
  done
}

say "✨ Dotfiles setup"
say "📍 Source: $DOTFILES_DIR"
say ""

auto_pull
say ""

install_dependencies
install_android_sdk
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

say ""
say "🛠️ Tools"
link_file "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.config/tmux/.tmux.conf"
link_file "$DOTFILES_DIR/config/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
link_file "$DOTFILES_DIR/config/karabiner" "$HOME/.config/karabiner"
link_file "$DOTFILES_DIR/config/mackup.cfg" "$HOME/.mackup.cfg"
restore_mackup_configs

say ""
"$DOTFILES_DIR/scripts/macos.sh"

say ""
launch_desktop_apps

say ""
say "👑 Dotfiles installed."
