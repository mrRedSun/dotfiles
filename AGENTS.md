# AGENTS.md

## Repository

Personal dotfiles for macOS and Linux. There is no build system, linter, or test suite.

## Layout

- `install.sh` — entry point: detects the OS (`uname`), auto-pulls when safe, and runs install modules in order. Idempotent; run from an interactive terminal (some modules need sudo, and macOS needs Mac App Store auth). `DOTFILES_DRY_RUN=1 ./install.sh` prints the module plan without executing anything.
- `scripts/lib.sh` — shared helpers sourced by the runner and every module (`say`, `detect_os`, `link_file`, `warm_sudo`).
- `scripts/common/<module>.sh` — OS-agnostic modules (`shell`, `git`, `tools`, `ai-skills`).
- `scripts/macos/<module>.sh` — macOS-only modules (`packages`, `android-sdk`, `preferences`, `defaults`).
- `scripts/linux/<module>.sh` — Linux-only modules (`packages`, `android-sdk`, `defaults`).
- `Brewfile` — curated Homebrew/mas package list used by `scripts/macos/packages.sh`. When a cask fails because stale files occupy its artifact paths, the module moves those files into the backup directory and reinstalls the cask.
- `zsh/`, `git/`, `config/` — config files symlinked into `$HOME` by the modules.
- `tests/docker-install-test.sh <image>` — end-to-end install test in a fresh container (create user, login, clone, install, assert, cleanup); used by `.github/workflows/docker-tests.yml` on `ubuntu:24.04` and `fedora:latest`.

## Conventions

- Module resolution: for each name in `MODULES` in `install.sh`, prefer `scripts/<os>/<name>.sh`, then fall back to `scripts/common/<name>.sh`; if neither exists the module is skipped (e.g. `preferences` on Linux).
- Modules are standalone scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, source `scripts/lib.sh`, do one job, and stay idempotent.
- Never overwrite user files: check before installing/linking, back up to `~/.dotfiles-backup/` instead.
- Keep shared helpers in `scripts/lib.sh`; do not duplicate them across modules.
- Prefer `config/mackup.cfg` copy mode for app preferences; never Mackup link mode.
- Shell configs are shared across OSes; guard macOS-only paths with `if [[ "$(uname -s)" == "Darwin" ]]` instead of forking config files.

## Workflow

- Deliver every requested change as a PR: do the work on a branch, push, open a PR describing the result, then ask the user if it can be merged immediately. Merge once they approve.

## Verification

- `bash -n` takes one script; check each file individually: `for f in install.sh scripts/lib.sh scripts/common/*.sh scripts/macos/*.sh scripts/linux/*.sh tests/*.sh; do bash -n "$f" || exit 1; done` — syntax check after edits.
- `for f in zsh/.zshrc zsh/.zprofile zsh/.zshenv; do zsh -n "$f" || exit 1; done` — syntax check after edits.
- `DOTFILES_DRY_RUN=1 ./install.sh` — verify module resolution for the current OS without side effects.
- `./tests/docker-install-test.sh ubuntu:24.04` (and optionally `fedora:latest`, `SKIP_ANDROID=1` for a quick run) — full install verification in Docker.
