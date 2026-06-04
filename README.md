# Dotfiles

Personal development environment configuration.

This repo currently manages existing dotfiles imported from `~/`. App and tool installation can be added later with a `Brewfile` or another bootstrap layer.

## What's Included

- Zsh config: `zsh/.zshrc`, `zsh/.zprofile`, `zsh/.zshenv`
- Git config: `git/.gitconfig`, `git/.gitignore`, `git/.gitignore_global`
- Neovim config: `config/nvim`
- tmux config: `config/tmux/.tmux.conf`
- AeroSpace config: `config/aerospace/aerospace.toml`
- Homebrew package list: `Brewfile`
- Install script: `install.sh`

## Install

From this repo:

```sh
./install.sh
```

The installer creates symlinks from this repo into your home directory. If a target file already exists and is not already the expected symlink, it is moved into `~/.dotfiles-backup/<timestamp>/` before the new link is created.

The installer is safe to run repeatedly. If this directory is a Git checkout with an upstream branch and no local changes, it pulls the latest dotfiles with `git pull --ff-only` before linking. If local changes are present, it skips the pull and keeps going.

## Homebrew

Install the selected package list with:

```sh
brew bundle --file Brewfile
```

The `Brewfile` is intentionally curated from the current machine. It does not include every installed transitive library, generated package, VS Code extension, or one-off app.

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
