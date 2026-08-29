#!/usr/bin/env bash
set -euo pipefail

# Link macOS-only app configs (AeroSpace, Karabiner, Mackup) and restore app
# preferences with Mackup copy mode.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🍎 Preferences"

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

link_file "$DOTFILES_DIR/config/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
link_file "$DOTFILES_DIR/config/karabiner" "$HOME/.config/karabiner"
link_file "$DOTFILES_DIR/config/mackup.cfg" "$HOME/.mackup.cfg"
restore_mackup_configs

say "✅ macOS preferences configured."
