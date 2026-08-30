#!/usr/bin/env bash
set -euo pipefail

# Install Homebrew and every Brewfile dependency, grouping password-gated
# casks and Mac App Store apps first.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🍺 Packages (Homebrew)"

BREW_BIN=""

# Casks in this list use pkg installers or system extensions. They are handled
# before the main Brewfile pass so password prompts are grouped together.
PASSWORD_CASKS=(karabiner-elements zulu@11 zulu@8)

# Mac App Store apps managed by mas. Keep IDs and names aligned by index.
MAS_APP_IDS=(1503446680 1451685025)
MAS_APP_NAMES=(PastePal WireGuard)

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

  mas list | awk '{print $1}' | grep -Fx "$app_id" >/dev/null
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

  # Guard the index expansion: empty arrays are fatal under `set -u` in the
  # bash 3.2 that ships with macOS.
  if [[ "${#missing_mas_ids[@]}" -gt 0 ]]; then
    for i in "${!missing_mas_ids[@]}"; do
      say "📲 Installing ${missing_mas_names[$i]} from the Mac App Store..."
      mas install "${missing_mas_ids[$i]}"
    done
  fi

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

# List Brewfile casks that are not installed. `bundle check` exits non-zero
# whenever anything is unmet, which is the expected outcome here. The list of
# unmet entries goes to stderr; the tap warnings on the same stream do not
# match the pattern.
missing_brewfile_casks() {
  HOMEBREW_BUNDLE_NO_UPGRADE=1 "$BREW_BIN" bundle check --verbose --file "$DOTFILES_DIR/Brewfile" 2>&1 |
    sed -n 's/^.* Cask \(.*\) needs to be installed.*/\1/p'
}

# Move the existing artifact targets of a not-installed cask into the backup
# directory. Paths are mirrored under the backup directory so the files can
# be restored as-is.
backup_conflicting_artifacts() {
  local cask="$1"
  local target
  local backup_path

  if ! command -v jq >/dev/null 2>&1; then
    say "⚠️  jq not found; cannot inspect artifacts of $cask."
    return 0
  fi

  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    [[ -e "$target" || -L "$target" ]] || continue

    backup_path="$BACKUP_DIR/${target#/}"
    mkdir -p "$(dirname "$backup_path")"
    mv "$target" "$backup_path"
    say "📦 Backed up: $target -> $backup_path"
  done < <("$BREW_BIN" info --cask --json=v2 "$cask" 2>/dev/null | jq -r '.casks[0].artifacts[]?.target // empty')
}

# Stale copies of cask artifacts fail the whole `brew bundle` pass: a manual
# app install too old to adopt, font files from an older release, or a
# Generic Artifact target left behind by an uninstalled cask. Back the
# conflicting files up, then install each missing cask on its own.
recover_failed_casks() {
  local cask
  local failed_count=0

  while IFS= read -r cask; do
    [[ -z "$cask" ]] && continue

    backup_conflicting_artifacts "$cask"
    if "$BREW_BIN" install --cask "$cask"; then
      say "✅ Installed $cask."
    else
      failed_count=$((failed_count + 1))
      say "❌ $cask still failed to install." >&2
    fi
  done < <(missing_brewfile_casks)

  [[ "$failed_count" -eq 0 ]]
}

# Install missing Brewfile items without upgrading already-installed
# dependencies; a routine dotfiles sync should not upgrade every outdated
# package on the machine.
install_dependencies() {
  if HOMEBREW_BUNDLE_NO_UPGRADE=1 "$BREW_BIN" bundle check --file "$DOTFILES_DIR/Brewfile"; then
    say "✅ Brewfile dependencies already installed."
    return 0
  fi

  say "📦 Installing Brewfile dependencies..."
  if HOMEBREW_BUNDLE_NO_UPGRADE=1 "$BREW_BIN" bundle install --file "$DOTFILES_DIR/Brewfile"; then
    return 0
  fi

  # One stale artifact must not leave the rest of the Brewfile uninstalled.
  recover_failed_casks || true

  if HOMEBREW_BUNDLE_NO_UPGRADE=1 "$BREW_BIN" bundle check --file "$DOTFILES_DIR/Brewfile"; then
    return 0
  fi

  say "❌ Some Brewfile dependencies failed to install. Run 'brew bundle install --verbose --file $DOTFILES_DIR/Brewfile' for the remaining errors." >&2
  return 1
}

install_homebrew
install_password_dependencies
install_dependencies

say "✅ Homebrew packages installed."
