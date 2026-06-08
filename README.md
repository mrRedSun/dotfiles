# Dotfiles

Personal development environment configuration and bootstrap script.

## What's Included

- Zsh config: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.zshenv`
- Git config: `git/.gitconfig`, `git/.gitignore`
- Neovim config: `config/nvim`
- tmux config: `config/tmux/.tmux.conf`
- AeroSpace config: `config/aerospace/aerospace.toml`
- Karabiner-Elements config: `config/karabiner`
- Mackup app preferences: `config/mackup.cfg`, `config/mackup`
- Rectangle Pro export: `config/rectangle-pro/RectangleProConfig.json`
- macOS tweaks: `scripts/macos.sh`
- Homebrew package list: `Brewfile`
- Install script: `install.sh`

## Install

On a new Mac, clone the repo and run the installer:

```sh
mkdir -p ~/Projects && git clone https://github.com/mrRedSun/dotfiles.git ~/Projects/dotfiles && cd ~/Projects/dotfiles && ./install.sh
```

From this repo:

```sh
./install.sh
```

The installer installs Homebrew if needed, installs the selected Brewfile packages, creates symlinks from this repo into your home directory, restores supported app preferences with Mackup copy mode, and applies macOS tweaks. If a target file already exists and is not already the expected symlink, it is moved into `~/.dotfiles-backup/<timestamp>/` before the new link is created.

Run the installer from an interactive terminal. Some Homebrew casks and Mac App Store installs need admin rights; the installer asks for your password once up front and keeps that sudo session alive until it finishes.

The installer is safe to run repeatedly. If this directory is a Git checkout with an upstream branch and no local changes, it pulls the latest dotfiles with `git pull --ff-only` before linking. If local changes are present, it skips the pull and keeps going.

It also applies a few macOS defaults: disables press-and-hold accent picking for Vim-style key repeat, disables natural scrolling, sets trackpad/mouse speed, keeps force click and right click enabled, disables smart typography substitutions, reduces window motion, prevents Spaces from switching automatically when activating apps, disables separate Spaces per display, puts the Dock on the right, enables Dock autohide, removes Dock show/hide animation delay, hides recent Dock apps, adds Downloads and Desktop stacks to the Dock, shows hidden files in Finder, and enables the Finder status bar. The separate-Spaces setting may require logging out and back in.

## Homebrew

The `Brewfile` is installed by `./install.sh` and is intentionally curated from the current machine. It does not include every installed transitive library, generated package, VS Code extension, or one-off app.

## Mackup

App preference files that are awkward to symlink or import manually are restored with Mackup. The repo uses a narrow Mackup config at `config/mackup.cfg`, currently scoped to iTerm2 only, with storage under `config/mackup`.

The installer links `~/.mackup.cfg` and runs:

```sh
mackup --config-file config/mackup.cfg restore --force
```

Use Mackup copy/restore mode for macOS app preferences. Do not use Mackup link mode on modern macOS.

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
