#!/usr/bin/env bash
set -euo pipefail

# Open GUI apps without stealing focus so first-run permission, login, or
# background-item prompts surface while setup is still fresh in memory.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🚀 Desktop apps"

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

launch_desktop_apps() {
  local app

  for app in "${DESKTOP_APPS[@]}"; do
    if open -gj -a "$app" >/dev/null 2>&1; then
      say "✅ Launched: $app"
    else
      say "⚠️  Could not launch: $app"
    fi
  done
}

launch_desktop_apps

say "✅ Desktop apps launched."
