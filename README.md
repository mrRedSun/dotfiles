# Dotfiles

Personal development environment configuration and bootstrap script for macOS and Linux.

## What's Included

- Zsh config: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.zshenv`
- Git config: `git/.gitconfig`, `git/.gitignore`
- Neovim config: `config/nvim`
- tmux config: `config/tmux/.tmux.conf`
- AeroSpace config: `config/aerospace/aerospace.toml` (macOS)
- Karabiner-Elements config: `config/karabiner` (macOS)
- Mackup app preferences: `config/mackup.cfg`, `config/mackup` (macOS)
- Rectangle Pro export: `config/rectangle-pro/RectangleProConfig.json` (macOS)
- Personal AI skills: `skills/`
- Install modules: `scripts/common/`, `scripts/macos/`, `scripts/linux/`
- Homebrew package list (macOS): `Brewfile`
- Install script: `install.sh`

## Install

On a new machine, clone the repo and run the installer:

```sh
mkdir -p ~/Projects && git clone https://github.com/mrRedSun/dotfiles.git ~/Projects/dotfiles && cd ~/Projects/dotfiles && ./install.sh
```

From this repo:

```sh
./install.sh
```

The installer detects the OS with `uname` and runs install modules in order. Each module prefers `scripts/<os>/<module>.sh` and falls back to `scripts/common/<module>.sh` when a shared version exists; modules without a variant for the current OS are skipped. On macOS this means Homebrew and the Brewfile, the Android SDK and a Pixel emulator, Oh My Zsh and its custom plugins (`zsh-vi-mode`, `zsh-autosuggestions`, `zsh-syntax-highlighting`), symlinks from this repo into your home directory, personal AI skills for Claude Code, Codex, and OpenCode, a Mackup restore, macOS `defaults` tweaks, and a first launch of desktop apps. On Linux it installs the equivalent apt packages, the Android SDK command-line tools with an x86_64 emulator, and the same shared shell/git/tool/skills links, plus a few GNOME tweaks.

If a target file already exists and is not already the expected symlink, it is moved into `~/.dotfiles-backup/<timestamp>/` before the new link is created.

Run the installer from an interactive terminal. Package modules need admin rights; the installer asks for your password once and keeps that sudo session alive until it finishes.

The installer is safe to run repeatedly. If this directory is a Git checkout with an upstream branch and no local changes, it pulls the latest dotfiles with `git pull --ff-only` before linking. If local changes are present, it skips the pull and keeps going.

To preview the module plan for the current OS without touching anything:

```sh
DOTFILES_DRY_RUN=1 ./install.sh
```

On macOS it also applies a few `defaults` tweaks: disables press-and-hold accent picking for Vim-style key repeat, disables natural scrolling, sets trackpad/mouse speed, keeps force click and right click enabled, disables smart typography substitutions, reduces window motion, prevents Spaces from switching automatically when activating apps, disables separate Spaces per display, puts the Dock on the right, enables Dock autohide, removes Dock show/hide animation delay, hides recent Dock apps, adds Downloads and Desktop stacks to the Dock, shows hidden files in Finder, and enables the Finder status bar. The separate-Spaces setting may require logging out and back in.

## Homebrew

The `Brewfile` is installed by `scripts/macos/packages.sh` and is intentionally curated from the current machine. It does not include every installed transitive library, generated package, VS Code extension, or one-off app.

On Linux, `scripts/linux/packages.sh` mirrors the CLI/core sections of the Brewfile with apt packages; optional packages are installed only when the distro repositories carry them.

## Mackup

App preference files that are awkward to symlink or import manually are restored with Mackup. The repo uses a narrow Mackup config at `config/mackup.cfg`, currently scoped to iTerm2 only, with storage under `config/mackup`.

The installer links `~/.mackup.cfg` and runs:

```sh
mackup --config-file config/mackup.cfg restore --force
```

Use Mackup copy/restore mode for macOS app preferences. Do not use Mackup link mode on modern macOS.

## AI Skills

Personal agent skills live in `skills/<skill-name>/SKILL.md`. See [SKILLS.md](SKILLS.md) for a short, practical catalog. The installer links each skill directory individually so existing unmanaged skills can remain alongside the repo-managed set:

- `~/.claude/skills/<skill-name>` for Claude Code
- `~/.agents/skills/<skill-name>` for Codex and OpenCode

Codex and OpenCode both discover the open-standard `~/.agents/skills` location. Using that shared location avoids duplicate skill definitions in OpenCode. Run only the skill-linking step with:

```sh
./scripts/common/ai-skills.sh
```

Existing destinations that are not already the expected symlink are moved into `~/.dotfiles-backup/<timestamp>/ai-skills/` first.

## Manual Imports

Some apps do not provide a safe command-line import path for public dotfiles.

Rectangle Pro preferences can be restored from:

```text
config/rectangle-pro/RectangleProConfig.json
```

Import it from Rectangle Pro's preferences UI.

## Customize

Edit the files in this repo, then open a new shell or reload Zsh:

```sh
source ~/.zshrc
```

For future machine-specific or private settings, prefer local files that are not committed:

- `~/.zshrc.local`
- `~/.gitconfig.local`

## Notes

This repo was seeded from the current home-directory configs. Before publishing it, review files such as `git/.gitconfig` and shell aliases for personal names, emails, hosts, and machine-specific paths.
