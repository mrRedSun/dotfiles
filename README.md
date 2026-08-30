# Dotfiles

My development environment for macOS and Linux: an installer, shell, Git, editor, and terminal configs, and a set of agent skills.

## What's included

- Zsh config: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.zshenv`
- Git config: `git/.gitconfig`, `git/.gitignore`
- Neovim config: `config/nvim`
- tmux config: `config/tmux/.tmux.conf`
- macOS app config: AeroSpace (`config/aerospace`), Karabiner-Elements (`config/karabiner`), Mackup (`config/mackup.cfg`, `config/mackup`), Rectangle Pro (`config/rectangle-pro`)
- Agent skills: `skills/`
- Install modules: `scripts/common/`, `scripts/macos/`, `scripts/linux/`
- Homebrew package list (macOS): `Brewfile`

## Install

On a new machine, clone the repo and run the installer:

```sh
mkdir -p ~/Projects && git clone https://github.com/mrRedSun/dotfiles.git ~/Projects/dotfiles && cd ~/Projects/dotfiles && ./install.sh
```

From an existing checkout, run `./install.sh`.

Run the installer from an interactive terminal. The package modules need admin rights: each one asks for your password and keeps the sudo session alive while it runs.

The installer is idempotent. Run it as often as you like; each module skips work that is already done. If the checkout is clean and has an upstream branch, the installer pulls the latest changes with `git pull --ff-only` before linking. If the working tree is dirty, it skips the pull and continues.

If a file exists at a link target and is not already the expected symlink, the installer moves the file into `~/.dotfiles-backup/<timestamp>/` before it creates the link.

To print the module plan for the current OS without running anything:

```sh
DOTFILES_DRY_RUN=1 ./install.sh
```

To exclude modules, pass a space-separated list in `DOTFILES_SKIP_MODULES`, such as `DOTFILES_SKIP_MODULES="android-sdk" ./install.sh`.

## How the installer works

The installer detects the OS with `uname` and runs modules in a fixed order. For each module it prefers `scripts/<os>/<module>.sh` and falls back to `scripts/common/<module>.sh`. If neither file exists, the installer skips the module.

On macOS, the modules install Homebrew and the `Brewfile`, the Android SDK with a Pixel emulator, Oh My Zsh with its custom plugins (`zsh-vi-mode`, `zsh-autosuggestions`, `zsh-syntax-highlighting`), the config symlinks, the agent skills, a Mackup restore, and the `defaults` tweaks.

On Linux, the modules install the apt or dnf package equivalents, the Android SDK command-line tools with an x86_64 emulator, the same shared symlinks and skills, and a few GNOME tweaks.

### What the defaults module changes on macOS

`scripts/macos/defaults.sh` applies these `defaults` tweaks:

- Key repeat: press-and-hold accent picking off, for Vim-style repeat.
- Input: natural scrolling off, trackpad and mouse speed at maximum, force click and right click on, smart typography substitutions off.
- Windows and Spaces: window motion reduced, apps no longer switch Spaces on activation, one set of Spaces across displays. The Spaces change takes effect after you log out and log back in.
- Dock: on the right, autohidden, no show or hide animation delay, recent apps hidden, Downloads and Desktop stacks added.
- Finder: hidden files shown, status bar shown.

## Packages

`scripts/macos/packages.sh` installs the `Brewfile`, which is curated from the current machine. It does not include every transitive library, generated package, VS Code extension, or one-off app.

`scripts/linux/packages.sh` mirrors most of the CLI and core sections of the `Brewfile` with apt (Debian and Ubuntu) or dnf (Fedora). Packages that your distro's repositories do not carry are skipped with a notice.

## Mackup

App preferences that are awkward to symlink are restored with Mackup, using the narrow config in `config/mackup.cfg` (iTerm2 only, storage under `config/mackup`). The installer links `~/.mackup.cfg` and runs:

```sh
mackup --config-file config/mackup.cfg restore --force
```

Use Mackup copy or restore mode for macOS app preferences. Mackup link mode breaks preferences on modern macOS.

## AI skills

Agent skills live in `skills/<skill-name>/SKILL.md`. See [SKILLS.md](SKILLS.md) for a catalog. The installer links each skill directory individually, so unmanaged skills stay alongside the repo-managed set:

- `~/.claude/skills/<skill-name>` for Claude Code
- `~/.agents/skills/<skill-name>` for Codex and OpenCode, which both discover this shared location

To run only the skill-linking step:

```sh
./scripts/common/ai-skills.sh
```

Destinations that are not already the expected symlink are moved into `~/.dotfiles-backup/<timestamp>/ai-skills/` first.

### Skill attribution

Most skills in `skills/` come from two public collections, some copied as-is and some lightly adapted:

- From [Matt Pocock](https://github.com/mattpocock)'s [mattpocock/skills](https://github.com/mattpocock/skills): `diagnosing-bugs`, `grilling`, `grill-me`, `handoff`, `resolving-merge-conflicts`, `wait-what`, `writing-for-agents`
- From [Michael Ramos](https://github.com/backnotprop)'s [backnotprop/pstack](https://github.com/backnotprop/pstack), which also ships in [cursor/plugins](https://github.com/cursor/plugins): `architect`, `arena`, `blast-radius`, `bro`, `how`, `interrogate`, `show-me-your-work`, `swarm`, `tdd`, `teach`, `technical-writing`, `unslop`, `why`

Credit for those skills belongs to their authors, and the upstream repos carry the canonical versions.

## Import Rectangle Pro manually

Rectangle Pro has no command-line import. Import `config/rectangle-pro/RectangleProConfig.json` from its preferences UI.

## Run the install tests

Every push runs the installer end-to-end in Docker on `ubuntu:24.04` and `fedora:latest` (`.github/workflows/docker-tests.yml`). Each run spawns a fresh container, creates a test user, logs in, clones the repo, runs the full install with the Android SDK, checks the results and an idempotent re-run, then deletes the container. To run the test locally without the Android download:

```sh
SKIP_ANDROID=1 ./tests/docker-install-test.sh ubuntu:24.04
```

## Customize

Edit the files in this repo, then open a new shell or reload Zsh:

```sh
source ~/.zshrc
```

Keep machine-specific or private settings in files that are not committed. `.zshrc` sources `~/.zshrc.local`, and `.gitconfig` includes `~/.gitconfig.local`.

## Before you publish

This repo was seeded from my home-directory configs. Review `git/.gitconfig` and the shell aliases for personal names, emails, hosts, and machine-specific paths.
