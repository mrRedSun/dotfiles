#!/usr/bin/env bash
set -euo pipefail

# Apply GNOME desktop tweaks mirroring the spirit of the macOS defaults:
# fast key repeat, classic scrolling direction, and no tap-to-click surprises.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🐧 Linux tweaks"

if ! command -v gsettings >/dev/null 2>&1; then
  say "⚠️  gsettings not found; skipping desktop tweaks."
  exit 0
fi

apply_gsetting() {
  local schema="$1"
  local key="$2"
  local value="$3"

  if gsettings writable "$schema" "$key" >/dev/null 2>&1; then
    gsettings set "$schema" "$key" "$value"
    say "✅ $schema $key = $value"
  else
    say "⏭️  Schema not available, skipping: $schema/$key"
  fi
}

# Fast key repeat for Vim-style navigation (macOS ApplePressAndHoldEnabled off).
apply_gsetting org.gnome.desktop.peripherals.keyboard delay 220
apply_gsetting org.gnome.desktop.peripherals.keyboard repeat-interval 30

# Classic (non-natural) scrolling, matching swipescrolldirection off on macOS.
apply_gsetting org.gnome.desktop.peripherals.touchpad natural-scroll false
apply_gsetting org.gnome.desktop.peripherals.mouse natural-scroll false

say "✅ Linux tweaks applied."
