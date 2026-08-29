#!/usr/bin/env bash
set -euo pipefail

# Install SDK packages that Homebrew does not manage directly, accept Android
# SDK licenses, and create a default Apple-Silicon-friendly Pixel emulator.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🤖 Android SDK"

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
ANDROID_AVD_CONFIG="$HOME/.android/avd/$ANDROID_AVD_NAME.avd/config.ini"

sdkmanager_bin="$(command -v sdkmanager || true)"
if [[ -z "$sdkmanager_bin" && -x /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager ]]; then
  sdkmanager_bin=/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager
fi

if [[ -z "$sdkmanager_bin" ]]; then
  say "⚠️  sdkmanager not found; skipping Android SDK package install."
  exit 0
fi

say "📦 Installing Android SDK packages..."
mkdir -p "$ANDROID_SDK_ROOT"
# `(yes || true)` keeps `yes` from failing the pipeline via SIGPIPE under
# pipefail once sdkmanager stops reading license prompts.
(yes || true) | env JAVA_HOME=/opt/homebrew/opt/openjdk@17 PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" \
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

if [[ -f "$ANDROID_AVD_CONFIG" ]]; then
  say "⌨️  Enabling hardware keyboard for Android emulator..."
  if grep -q '^hw.keyboard=' "$ANDROID_AVD_CONFIG"; then
    sed -i '' 's/^hw.keyboard=.*/hw.keyboard=yes/' "$ANDROID_AVD_CONFIG"
  else
    printf '%s\n' 'hw.keyboard=yes' >>"$ANDROID_AVD_CONFIG"
  fi
fi

say "✅ Android SDK installed."
