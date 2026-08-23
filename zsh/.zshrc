# Interactive shell configuration
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

ZSH_THEME="mira" # set by `omz`

## Plugins
plugins=(
    git
    zsh-vi-mode
    zsh-autosuggestions
    sudo
    fzf
    flutter
    # Keep last: syntax highlighting must wrap all other plugins/widgets.
    zsh-syntax-highlighting
)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

## zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# 🔗 Aliases

## General aliases 📝
alias vi=nvim
alias vim=nvim
alias conf="nvim ~/.zshrc && zsh" # Edit .zshrc file

# claude code
alias clauded="claude --dangerously-skip-permissions"
alias claudemit="claude --agent ticket-code-reviewer --dangerously-skip-permissions"


## Flutter and Dart aliases 🦋🎯
alias flutter_cleaner="flutter clean && cd ios && pod deintegrate && flutter pub get && pod install --repo-update && cd .. && flutter pub get && rm -rf ~/Library/Developer/Xcode/DerivedData"
alias flutter="fvm flutter"
alias codegen="fvm flutter pub run build_runner build --delete-conflicting-outputs"
alias codegen-watch="fvm flutter pub run build_runner watch --delete-conflicting-outputs"
alias dart="fvm dart"
alias fpg="flutter pub get"
alias f="flutter pub get"

# NVM
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f "$HOME/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# cool aliases
alias finger='adb -e emu finger touch 1 && adb -e emu finger remove 1'

alias ls="eza --icons=always"
alias vimconf="cd ~/.config/nvim/ && nvim ."

# tmux
alias tmux="tmux -f $HOME/.config/tmux/.tmux.conf"
