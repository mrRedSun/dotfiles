#!/usr/bin/env bash
set -euo pipefail

say() {
  printf '%s\n' "$1"
}

add_dock_stack() {
  local label="$1"
  local path="$2"
  local arrangement="$3"

  if defaults read com.apple.dock persistent-others 2>/dev/null | grep -Fq "file://$path/"; then
    say "✅ Dock stack already present: $label"
    return 0
  fi

  defaults write com.apple.dock persistent-others -array-add \
    "<dict><key>tile-data</key><dict><key>arrangement</key><integer>$arrangement</integer><key>displayas</key><integer>0</integer><key>file-data</key><dict><key>_CFURLString</key><string>file://$path/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>$label</string><key>preferreditemsize</key><integer>-1</integer><key>showas</key><integer>0</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"
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
defaults write -g com.apple.swipescrolldirection -bool false

# Trackpad and mouse feel.
defaults write -g com.apple.trackpad.scaling -float 3
defaults write -g com.apple.mouse.scaling -float 3
defaults write -g com.apple.trackpad.forceClick -bool true
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool false
  defaults write "$domain" TrackpadRightClick -bool true
  defaults write "$domain" TrackpadCornerSecondaryClick -int 0
  defaults write "$domain" TrackpadThreeFingerDrag -bool false
  defaults write "$domain" TrackpadTwoFingerDoubleTapGesture -int 1
  defaults write "$domain" TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
  defaults write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadThreeFingerVertSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
  defaults write "$domain" FirstClickThreshold -int 1
  defaults write "$domain" SecondClickThreshold -int 1
done

# Keep the Dock out of the way.
defaults write com.apple.dock orientation -string right
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock expose-group-apps -bool true
add_dock_stack "Downloads" "$HOME/Downloads" 2
add_dock_stack "Desktop" "$HOME/Desktop" 3

# Finder defaults.
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

say "✅ macOS tweaks applied."
