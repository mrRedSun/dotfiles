#!/usr/bin/env bash
set -euo pipefail

# Install apt packages mirroring the CLI/core sections of the macOS Brewfile.
# Optional packages are installed only when the distro repositories carry them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🍺 Packages (apt)"

# Core CLI utilities, build tooling, and the zsh/java prerequisites the other
# modules rely on.
APT_PACKAGES=(
  "build-essential"
  "git"
  "gh"
  "curl"
  "wget"
  "ripgrep"
  "fd-find"
  "fzf"
  "gawk"
  "htop"
  "jq"
  "tmux"
  "neovim"
  "tree"
  "unzip"
  "zsh"
  "openjdk-17-jdk"
)

# Mirrors more of the Brewfile where available; distros without these packages
# skip them rather than fail.
APT_OPTIONAL_PACKAGES=(
  "cmake"
  "ninja-build"
  "ccache"
  "pipx"
  "gradle"
  "scrcpy"
  "minicom"
  "aria2"
  "eza"
  "lazygit"
  "nmap"
  "rclone"
  "smartmontools"
  "speedtest-cli"
  "wireguard-tools"
  "imagemagick"
  "ghostscript"
  "media-info"
  "mpv"
)

if ! command -v apt-get >/dev/null 2>&1; then
  say "❌ apt-get not found; add a packages module for this distro." >&2
  exit 1
fi

is_apt_package_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

is_apt_package_available() {
  apt-cache show "$1" >/dev/null 2>&1
}

collect_missing_packages() {
  local package

  for package in "$@"; do
    if ! is_apt_package_installed "$package"; then
      printf '%s\n' "$package"
    fi
  done
}

install_apt_packages() {
  local to_install=("$@")
  local available_to_install=()
  local package

  for package in "${to_install[@]}"; do
    if is_apt_package_available "$package"; then
      available_to_install+=("$package")
    else
      say "⏭️  Not in apt repositories, skipping: $package"
    fi
  done

  if [[ "${#available_to_install[@]}" -eq 0 ]]; then
    return 0
  fi

  sudo apt-get install -y "${available_to_install[@]}"
}

mapfile -t missing_core < <(collect_missing_packages "${APT_PACKAGES[@]}")
mapfile -t missing_optional < <(collect_missing_packages "${APT_OPTIONAL_PACKAGES[@]}")

if [[ "${#missing_core[@]}" -eq 0 && "${#missing_optional[@]}" -eq 0 ]]; then
  say "✅ apt packages already installed."
  exit 0
fi

warm_sudo
say "📦 Refreshing apt package index..."
sudo apt-get update

if [[ "${#missing_core[@]}" -gt 0 ]]; then
  say "📦 Installing ${#missing_core[@]} core apt packages..."
  install_apt_packages "${missing_core[@]}"
fi

if [[ "${#missing_optional[@]}" -gt 0 ]]; then
  say "📦 Installing available optional apt packages..."
  install_apt_packages "${missing_optional[@]}"
fi

say "✅ apt packages installed."
