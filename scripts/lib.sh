# Shared helpers for the installer and its modules. Source this file; never
# execute it directly.

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

SUDO_WARMED=0
SUDO_KEEPALIVE_PID=""

say() {
  printf '%s\n' "$1"
}

# Map uname to the module directory name for the current platform.
detect_os() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' "macos" ;;
    Linux) printf '%s\n' "linux" ;;
    *)
      say "❌ Unsupported operating system: $(uname -s)" >&2
      return 1
      ;;
  esac
}

# Symlink a repo file/directory into place. Existing user files are backed up
# to $BACKUP_DIR instead of overwritten.
link_file() {
  local source_path="$1"
  local target_path="$2"

  if [[ ! -e "$source_path" ]]; then
    say "❌ Missing source: $source_path" >&2
    return 1
  fi

  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_path" ]]; then
    say "✅ Already linked: $target_path"
    return 0
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target_path" "$BACKUP_DIR/"
    say "📦 Backed up: $target_path -> $BACKUP_DIR/"
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  say "🔗 Linked: $target_path -> $source_path"
}

# Ask for sudo once and keep the ticket warm while long downloads/installers
# run. Passwordless sudo (CI, containers, cloud images) is detected first;
# non-interactive runs without it fail early so they do not half-install
# packages.
warm_sudo() {
  if [[ "$SUDO_WARMED" -eq 1 ]]; then
    return 0
  fi

  sudo -k
  # `sudo -n -v` still demands a password under command-scoped NOPASSWD rules;
  # probing with a real command covers every configuration.
  if sudo -n true 2>/dev/null; then
    SUDO_WARMED=1
    return 0
  fi

  if [[ ! -t 0 ]]; then
    say "❌ This step requires sudo. Run ./install.sh from an interactive terminal so it can ask for your password once." >&2
    return 1
  else
    say "🔐 Refreshing sudo credentials for package installers..."
    sudo -v
    SUDO_WARMED=1
  fi

  while true; do
    sudo -n -v >/dev/null 2>&1 || exit
    sleep 60
  done &
  SUDO_KEEPALIVE_PID="$!"

  trap '[[ -n "$SUDO_KEEPALIVE_PID" ]] && kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true' EXIT
}
