#!/usr/bin/env bash
set -euo pipefail

say() {
  printf '%s\n' "$1"
}

say "🍎 Applying macOS tweaks..."

# Make press-and-hold repeat keys instead of showing the accent picker.
# This is needed for Vim-style navigation in many editors.
defaults write -g ApplePressAndHoldEnabled -bool false

# Keep the Dock out of the way.
defaults write com.apple.dock orientation -string right
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock launchanim -bool false

killall Dock >/dev/null 2>&1 || true

say "✅ macOS tweaks applied."
