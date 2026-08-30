#!/usr/bin/env bash
set -euo pipefail

# Install system packages mirroring the CLI/core sections of the macOS
# Brewfile. Supports apt (Debian/Ubuntu) and dnf (Fedora). Optional packages
# are installed only when the distro repositories carry them; the module makes
# zsh the login shell so the shared zsh configs actually apply.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

# Core CLI utilities, build tooling, and the zsh/java prerequisites the other
# modules rely on. Names differ between apt and dnf.
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
DNF_PACKAGES=(
  "gcc"
  "gcc-c++"
  "make"
  "git"
  "curl"
  "wget"
  "ripgrep"
  "fd"
  "fzf"
  "gawk"
  "htop"
  "jq"
  "tmux"
  "neovim"
  "tree"
  "unzip"
  "zsh"
  "java-17-openjdk-devel"
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
DNF_OPTIONAL_PACKAGES=(
  "gh"
  "cmake"
  "ninja-build"
  "ccache"
  "pipx"
  "gradle"
  "minicom"
  "aria2"
  "nmap"
  "rclone"
  "smartmontools"
  "wireguard-tools"
  "imagemagick"
  "ghostscript"
  "mpv"
)

detect_package_family() {
  if command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' "apt"
  elif command -v dnf >/dev/null 2>&1; then
    printf '%s\n' "dnf"
  else
    return 1
  fi
}

# dpkg -s also reports removed-but-not-purged packages as installed; require
# the "ii" (installed) status abbreviations instead.
is_installed_apt() {
  dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null | grep -q '^ii'
}
is_installed_dnf() {
  rpm -q "$1" >/dev/null 2>&1
}

# apt-cache show exits 0 with empty output for virtual packages and prints
# noisy errors for unknown ones; require an actual Package record.
is_available_apt() {
  apt-cache show "$1" 2>/dev/null | grep -q '^Package:'
}
is_available_dnf() {
  dnf -q repoquery "$1" 2>/dev/null | grep -q .
}

refresh_metadata_apt() {
  sudo apt-get update
}
refresh_metadata_dnf() {
  sudo dnf -q makecache
}

install_apt_packages() {
  local package
  local available=()

  for package in "$@"; do
    if is_available_apt "$package"; then
      available+=("$package")
    else
      say "⏭️  Not in apt repositories, skipping: $package"
    fi
  done

  if [[ "${#available[@]}" -eq 0 ]]; then
    return 0
  fi

  sudo apt-get install -y "${available[@]}"
}

install_dnf_packages() {
  local package
  local available=()

  for package in "$@"; do
    if is_available_dnf "$package"; then
      available+=("$package")
    else
      say "⏭️  Not in dnf repositories, skipping: $package"
    fi
  done

  if [[ "${#available[@]}" -eq 0 ]]; then
    return 0
  fi

  sudo dnf install -y "${available[@]}"
}

collect_missing_packages() {
  local is_installed="is_installed_$PACKAGE_FAMILY"
  local package

  for package in "$@"; do
    "$is_installed" "$package" || printf '%s\n' "$package"
  done
}

if ! PACKAGE_FAMILY="$(detect_package_family)"; then
  say "❌ Neither apt-get nor dnf found; add a packages module for this distro." >&2
  exit 1
fi

say "🍺 Packages ($PACKAGE_FAMILY)"

if [[ "$PACKAGE_FAMILY" == "apt" ]]; then
  core_packages=("${APT_PACKAGES[@]}")
  optional_packages=("${APT_OPTIONAL_PACKAGES[@]}")
else
  core_packages=("${DNF_PACKAGES[@]}")
  optional_packages=("${DNF_OPTIONAL_PACKAGES[@]}")
fi

mapfile -t missing_core < <(collect_missing_packages "${core_packages[@]}")
mapfile -t missing_optional < <(collect_missing_packages "${optional_packages[@]}")

if [[ "${#missing_core[@]}" -gt 0 || "${#missing_optional[@]}" -gt 0 ]]; then
  warm_sudo
  say "📦 Refreshing $PACKAGE_FAMILY package metadata..."
  "refresh_metadata_$PACKAGE_FAMILY"

  if [[ "${#missing_core[@]}" -gt 0 ]]; then
    say "📦 Installing ${#missing_core[@]} core packages..."
    "install_${PACKAGE_FAMILY}_packages" "${missing_core[@]}"
  fi

  if [[ "${#missing_optional[@]}" -gt 0 ]]; then
    say "📦 Installing available optional packages..."
    "install_${PACKAGE_FAMILY}_packages" "${missing_optional[@]}"
  fi
else
  say "✅ Packages already installed."
fi

# The repo is zsh-centric; make zsh the login shell so ~/.zprofile applies.
user_name="$(id -un)"
login_shell="$(getent passwd "$user_name" | cut -d: -f7)"
if [[ "$login_shell" != "*/zsh" ]]; then
  zsh_path="$(command -v zsh || true)"
  if [[ -z "$zsh_path" ]]; then
    say "⚠️  zsh not found; leaving login shell as $login_shell." >&2
  else
    warm_sudo
    say "🐚 Setting zsh as the login shell for $user_name..."
    sudo usermod -s "$zsh_path" "$user_name"
  fi
fi

say "✅ System packages installed."
