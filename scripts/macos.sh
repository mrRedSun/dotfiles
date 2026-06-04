#!/usr/bin/env bash
set -euo pipefail

say() {
  printf '%s\n' "$1"
}

say "🍎 Applying macOS tweaks..."

# Make press-and-hold repeat keys instead of showing the accent picker.
# This is needed for Vim-style navigation in many editors.
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g AppleKeyboardUIMode -int 2

# Keep typing behavior predictable for code and terminal work.
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false

# Reduce system window motion.
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
defaults write -g AppleSpacesSwitchOnActivate -bool false
defaults write com.apple.spaces spans-displays -bool true

# Keep the Dock out of the way.
defaults write com.apple.dock orientation -string right
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock expose-group-apps -bool true

# Finder defaults.
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

say "✅ macOS tweaks applied."
