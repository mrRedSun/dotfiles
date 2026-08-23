# AGENTS.md

## Repository

Personal macOS dotfiles. There is no build system, linter, or test suite.

## Layout

- `install.sh` — bootstrap script: Homebrew/Brewfile, Android SDK, Oh My Zsh + custom plugins, symlinks, Mackup restore, macOS defaults. Idempotent; run from an interactive terminal (needs sudo and Mac App Store auth).
- `scripts/macos.sh` — macOS `defaults` tweaks, invoked by `install.sh`.
- `Brewfile` — curated Homebrew/mas package list.
- `zsh/`, `git/`, `config/` — config files symlinked into `$HOME` by `install.sh`.

## Conventions

- `install.sh` must stay idempotent: check before installing/linking, never overwrite user files (back up to `~/.dotfiles-backup/` instead).
- Shell scripts use `#!/usr/bin/env bash` with `set -euo pipefail`.
- Prefer `config/mackup.cfg` copy mode for app preferences; never Mackup link mode.

## Verification

- `bash -n install.sh scripts/macos.sh` — syntax check after edits.
- `zsh -n zsh/.zshrc zsh/.zprofile zsh/.zshenv` — syntax check after edits.
