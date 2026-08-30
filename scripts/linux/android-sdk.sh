#!/usr/bin/env bash
set -euo pipefail

# Install the Android SDK command-line tools from Google's archive, accept
# licenses, and create a ready-to-run x86_64 Pixel emulator.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🤖 Android SDK"

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
ANDROID_SDK_PACKAGES=(
  "cmdline-tools;latest"
  "emulator"
  "platform-tools"
  "platforms;android-35"
  "build-tools;35.0.0"
  "system-images;android-35;google_apis;x86_64"
)
ANDROID_AVD_NAME="Pixel_9_API_35"
ANDROID_AVD_DEVICE="pixel_9"
ANDROID_AVD_PACKAGE="system-images;android-35;google_apis;x86_64"
ANDROID_AVD_CONFIG="$HOME/.android/avd/$ANDROID_AVD_NAME.avd/config.ini"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# sdkmanager and avdmanager require JAVA_HOME; derive it from the java on PATH
# when it is not already set.
resolve_java_home() {
  if [[ -n "${JAVA_HOME:-}" ]]; then
    return 0
  fi

  local java_bin
  if ! java_bin="$(readlink -f "$(command -v java)" 2>/dev/null)"; then
    say "❌ java not found; install openjdk-17-jdk first (packages module)." >&2
    return 1
  fi

  if [[ "$java_bin" == */bin/java ]]; then
    JAVA_HOME="${java_bin%/bin/java}"
    export JAVA_HOME
  fi
}

# Download a pinned cmdline-tools build used only to bootstrap the SDK. The
# pinned archive can be older than the repository catalog, so packages are
# installed through it and "cmdline-tools;latest" upgrades itself into
# cmdline-tools/latest with the current device catalog; the bootstrap copy is
# removed afterwards.
install_cmdline_tools() {
  local tmp_dir

  if [[ -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
    say "✅ Android cmdline-tools already installed."
    return 0
  fi

  say "⬇️  Bootstrapping Android cmdline-tools..."
  tmp_dir="$(mktemp -d)"
  if ! curl -fsSL "$CMDLINE_TOOLS_URL" -o "$tmp_dir/cmdline-tools.zip" ||
    ! unzip -q "$tmp_dir/cmdline-tools.zip" -d "$tmp_dir"; then
    rm -rf "$tmp_dir"
    say "❌ Failed to download/extract Android cmdline-tools." >&2
    return 1
  fi
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/bootstrap"
  mv "$tmp_dir/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/bootstrap"
  rm -rf "$tmp_dir"
}

resolve_java_home
install_cmdline_tools

sdkmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$sdkmanager_bin" ]]; then
  sdkmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/bootstrap/bin/sdkmanager"
fi

say "📦 Installing Android SDK packages..."
mkdir -p "$ANDROID_SDK_ROOT"
# `(yes || true)` keeps `yes` from failing the pipeline via SIGPIPE under
# pipefail once sdkmanager stops reading license prompts.
(yes || true) | "$sdkmanager_bin" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null
"$sdkmanager_bin" --sdk_root="$ANDROID_SDK_ROOT" "${ANDROID_SDK_PACKAGES[@]}"

if [[ -d "$ANDROID_SDK_ROOT/cmdline-tools/bootstrap" && -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager" ]]; then
  say "🧹 Removing bootstrap cmdline-tools..."
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/bootstrap"
fi

avdmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager"

if ! "$avdmanager_bin" list avd | grep -Eq "^[[:space:]]*Name: ${ANDROID_AVD_NAME}$"; then
  say "📱 Creating Android emulator: $ANDROID_AVD_NAME"
  echo "no" | "$avdmanager_bin" create avd --name "$ANDROID_AVD_NAME" --package "$ANDROID_AVD_PACKAGE" --device "$ANDROID_AVD_DEVICE"
fi

if [[ -f "$ANDROID_AVD_CONFIG" ]]; then
  say "⌨️  Enabling hardware keyboard for Android emulator..."
  if grep -q '^hw.keyboard=' "$ANDROID_AVD_CONFIG"; then
    sed -i 's/^hw.keyboard=.*/hw.keyboard=yes/' "$ANDROID_AVD_CONFIG"
  else
    printf '%s\n' 'hw.keyboard=yes' >>"$ANDROID_AVD_CONFIG"
  fi
fi

if [[ ! -e /dev/kvm ]]; then
  say "⚠️  /dev/kvm not found; the emulator will be very slow without KVM."
fi

say "✅ Android SDK installed."
