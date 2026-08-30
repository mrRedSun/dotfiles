#!/usr/bin/env bash
set -euo pipefail

# End-to-end install test inside a fresh Docker container.
#
# Flow: pull image -> spawn container -> create "tester" user with a password
# and passwordless sudo -> login as tester -> git clone the repo (from a
# read-only bind mount of the working repo) -> run ./install.sh -> assert the
# outcome (exit 0, links, tools, optional Android SDK) -> run the installer a
# second time to prove idempotency -> delete the container.
#
# Usage:
#   tests/docker-install-test.sh <image>          # e.g. ubuntu:24.04, fedora:latest
#
# Environment:
#   SKIP_ANDROID=1        skip the android-sdk module (fast mode)
#   COMMITISH=<sha>       commit to test (default: host repo HEAD)
#   KEEP_ON_FAILURE=1     keep the container around after a failed run
#   TEST_USER_PASSWORD    password for the tester user (default: dotfiles-test)

IMAGE="${1:?usage: tests/docker-install-test.sh <image> (e.g. ubuntu:24.04, fedora:latest)}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMITISH="${COMMITISH:-$(git -C "$REPO_ROOT" rev-parse HEAD)}"
TEST_USER="tester"
TEST_USER_PASSWORD="${TEST_USER_PASSWORD:-dotfiles-test}"
CONTAINER="dotfiles-install-test-$(printf '%s' "$IMAGE" | tr -c 'a-zA-Z0-9' '-')"

PASS=0
FAIL=0

say() {
  printf '%s\n' "$1"
}

fail_summary() {
  if [[ "$FAIL" -gt 0 ]]; then
    say ""
    say "❌ $FAIL check(s) failed, $PASS passed."
    exit 1
  fi
}

cleanup() {
  if [[ "$FAIL" -eq 0 || "${KEEP_ON_FAILURE:-0}" != "1" ]]; then
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  else
    say "🧪 Keeping container for debugging: $CONTAINER"
  fi
}
trap cleanup EXIT

# check <name> <command...>  — runs the command; failure is recorded, not fatal.
check() {
  local name="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    say "  ✅ $name"
  else
    FAIL=$((FAIL + 1))
    say "  ❌ $name"
  fi
}

exec_root() {
  docker exec "$CONTAINER" bash -c "$1"
}
exec_user() {
  # Login shell via su - so .zprofile/.zshrc semantics are exercised.
  docker exec -t "$CONTAINER" su - "$TEST_USER" -c "$1"
}

say "🧪 Docker install test"
say "   image:     $IMAGE"
say "   commit:    $COMMITISH"
say "   container: $CONTAINER"
say ""

say "🐳 Pulling and starting $IMAGE..."
docker pull -q "$IMAGE" >/dev/null
docker run -d --name "$CONTAINER" -v "$REPO_ROOT:/host-repo:ro" "$IMAGE" sleep infinity >/dev/null

say "🔧 Preparing container (git, sudo, $TEST_USER user)..."
FAMILY="$(exec_root 'command -v apt-get >/dev/null 2>&1 && echo apt || echo dnf')"
if [[ "$FAMILY" == "apt" ]]; then
  exec_root 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq git sudo >/dev/null 2>&1'
else
  exec_root 'dnf -y -q install git sudo >/dev/null 2>&1'
fi
exec_root "useradd -m -s /bin/bash $TEST_USER && echo '$TEST_USER:$TEST_USER_PASSWORD' | chpasswd && echo '$TEST_USER ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$TEST_USER && chmod 440 /etc/sudoers.d/$TEST_USER"

say "📥 Cloning repo as $TEST_USER (login shell)..."
exec_user 'git config --global --add safe.directory /host-repo && git clone -q /host-repo ~/Projects/dotfiles && git -C ~/Projects/dotfiles checkout -q '"$COMMITISH"

say ""
say "🚀 Running ./install.sh (SKIP_ANDROID=${SKIP_ANDROID:-0})..."
INSTALL_ENV=""
if [[ "${SKIP_ANDROID:-0}" == "1" ]]; then
  INSTALL_ENV="DOTFILES_SKIP_MODULES=android-sdk "
fi
if exec_user "$INSTALL_ENV"'cd ~/Projects/dotfiles && ./install.sh'; then
  PASS=$((PASS + 1))
  say "  ✅ install.sh exited 0"
else
  FAIL=$((FAIL + 1))
  say "  ❌ install.sh exited non-zero"
  fail_summary
fi

say ""
say "🔎 Verifying results..."
check "login shell is zsh" exec_root "[[ \"\$(getent passwd $TEST_USER | cut -d: -f7)\" == */zsh ]]"
check "~/.zshrc linked to repo" exec_user '[[ "$(readlink ~/.zshrc)" == */dotfiles/zsh/.zshrc ]]'
check "~/.zprofile linked to repo" exec_user '[[ "$(readlink ~/.zprofile)" == */dotfiles/zsh/.zprofile ]]'
check "~/.gitconfig linked to repo" exec_user '[[ "$(readlink ~/.gitconfig)" == */dotfiles/git/.gitconfig ]]'
check "~/.config/nvim linked to repo" exec_user '[[ "$(readlink ~/.config/nvim)" == */dotfiles/config/nvim ]]'
check "Oh My Zsh installed" exec_user '[[ -f ~/.oh-my-zsh/oh-my-zsh.sh ]]'
check "zsh-vi-mode plugin" exec_user '[[ -d ~/.oh-my-zsh/custom/plugins/zsh-vi-mode ]]'
check "zsh-autosuggestions plugin" exec_user '[[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]'
check "zsh-syntax-highlighting plugin" exec_user '[[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]'
check "AI skills linked for Claude Code" exec_user '[[ -L ~/.claude/skills/why ]]'
check "AI skills linked for Codex/OpenCode" exec_user '[[ -L ~/.agents/skills/why ]]'
check "zsh login shell loads .zprofile (ANDROID_HOME)" exec_user '[[ -n "$ANDROID_HOME" ]]'
check "git works" exec_user 'git --version'

if [[ "${SKIP_ANDROID:-0}" != "1" ]]; then
  check "Android cmdline-tools sdkmanager" exec_user '[[ -x ~/Android/Sdk/cmdline-tools/latest/bin/sdkmanager ]]'
  check "Android emulator AVD created" exec_user '~/Android/Sdk/cmdline-tools/latest/bin/avdmanager list avd | grep -q "Name: Pixel_9_API_35"'
fi

say ""
say "🔁 Running ./install.sh again (idempotency)..."
if exec_user "$INSTALL_ENV"'cd ~/Projects/dotfiles && ./install.sh > /tmp/install-rerun.log 2>&1'; then
  PASS=$((PASS + 1))
  say "  ✅ second run exited 0"
else
  FAIL=$((FAIL + 1))
  say "  ❌ second run exited non-zero (see /tmp/install-rerun.log in container)"
fi
check "second run skipped existing work" exec_user 'grep -q "Already linked" /tmp/install-rerun.log'

fail_summary
say ""
say "✅ All $PASS checks passed on $IMAGE."
