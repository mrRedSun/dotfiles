#!/usr/bin/env bash
set -euo pipefail

# Link the cross-platform tool configs (Neovim, tmux) into $HOME.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

say "🛠️ Tools"

install_linux_neovim() (
  local nvim_path arch checksum archive temp_dir install_dir
  nvim_path="$HOME/.local/bin/nvim"
  [[ -x "$nvim_path" ]] || nvim_path="$(command -v nvim || true)"
  if [[ -n "$nvim_path" ]] && "$nvim_path" --clean --headless \
    '+lua if vim.fn.has("nvim-0.11.2") == 0 then os.exit(1) end' +qa >/dev/null 2>&1; then
    say "✅ Neovim meets LazyVim's minimum version."
    return
  fi

  case "$(uname -m)" in
    x86_64)
      arch="x86_64"
      checksum="bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875"
      ;;
    aarch64|arm64)
      arch="arm64"
      checksum="1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725"
      ;;
    *) say "❌ No Neovim release configured for $(uname -m)." >&2; return 1 ;;
  esac

  archive="nvim-linux-$arch.tar.gz"
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  say "⬇️ Installing Neovim v0.12.5 for LazyVim..."
  curl -fL --retry 3 "https://github.com/neovim/neovim/releases/download/v0.12.5/$archive" \
    -o "$temp_dir/$archive"
  printf '%s  %s\n' "$checksum" "$temp_dir/$archive" | sha256sum -c -
  install_dir="$HOME/.local/opt/neovim-v0.12.5"
  mkdir -p "$install_dir"
  tar -xzf "$temp_dir/$archive" -C "$install_dir"
  "$install_dir/nvim-linux-$arch/bin/nvim" --clean --headless \
    '+lua if vim.fn.has("nvim-0.11.2") == 0 then os.exit(1) end' +qa
  link_file "$install_dir/nvim-linux-$arch/bin/nvim" "$HOME/.local/bin/nvim"
)

if [[ "$(detect_os)" == "linux" ]]; then
  install_linux_neovim
fi

link_file "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
link_file "$DOTFILES_DIR/config/tmux/.tmux.conf" "$HOME/.config/tmux/.tmux.conf"

say "✅ Tools configured."
