# Environment variables
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

export RUBY_CFLAGS="-Wno-error=implicit-function-declaration"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# 🛣️ Path modifications

export PATH="$HOME/.redscripts:$PATH"

## System binaries 🖥️
export PATH="/usr/local/bin:$PATH" # Add system-wide binaries

## Homebrew 🍺
export PATH="/opt/homebrew/bin:$PATH"                  # Homebrew binaries
export PATH="/opt/homebrew/sbin:$PATH"                 # Homebrew sbin
export PATH="/opt/homebrew/opt:$PATH"                  # Homebrew optional packages
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH" # MySQL client

## Dotnet 💻
export PATH="/usr/local/share/dotnet:$PATH" # .NET SDK

## Pyenv 🐍
export PATH="$HOME/.pyenv/bin:$PATH" # Pyenv binaries

## Android SDK 🤖
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH" # Android platform tools
export PATH="$HOME/Library/Android/sdk/emulator:$PATH"       # Android emulator

## Flutter and Dart 🦋🎯
export PATH="$HOME/fvm/default/bin:$PATH" # Flutter Version Manager
export PATH="$HOME/.pub-cache/bin:$PATH"  # Dart pub cache binaries

## mbed TLS 🔒
export PATH="/opt/homebrew/opt/mbedtls@2/bin:$PATH" # mbed TLS binaries

## Ruby 💎
export PATH="/usr/local/opt/ruby/bin:$PATH" # Ruby binaries

## Qt 📦
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"            # Qt5 binaries
export PATH="$HOME/Applications/Qt/6.6.3/macos/bin:$PATH" # Qt6 binaries

## Android Studio 🤖
export PATH="/Applications/Android Studio.app/Contents/MacOS:$PATH" # Android Studio binaries

## GStreamer 🎵
export PATH="/Library/Frameworks/GStreamer.framework/Commands:$PATH" # GStreamer commands

## Local binaries 🏠
export PATH="$HOME/.local/bin:$PATH" # Local user binaries

# 🗂️ Other environment variables

## PKG_CONFIG_PATH settings 📦
export PKG_CONFIG_PATH="/opt/homebrew/opt/curl/lib/pkgconfig:$PKG_CONFIG_PATH"                                             # curl pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/opt/expat/lib/pkgconfig:$PKG_CONFIG_PATH"                                            # expat pkg-config
export PKG_CONFIG_PATH="/Library/Frameworks/GStreamer.framework/Versions/1.0/lib/pkgconfig:$PKG_CONFIG_PATH"               # GStreamer pkg-config
export PKG_CONFIG_PATH="/Library/Frameworks/GStreamer.framework/Versions/1.0/lib/gstreamer-1.0/pkgconfig:$PKG_CONFIG_PATH" # GStreamer-1.0 pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"                                           # libffi pkg-config

## LDFLAGS and CPPFLAGS for libffi
export LDFLAGS="-L/opt/homebrew/opt/libffi/lib"      # Linker flags for libffi
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include" # Preprocessor flags for libffi

export ZSH="$HOME/.oh-my-zsh"
export CASE_SENSITIVE="false"
export Qt5_DIR="/opt/homebrew/opt/qt@5/lib/cmake/Qt5"

# ⚙️ Initialization commands

## Pyenv initialization 🐍
#eval "$(pyenv init -)"
#eval "$(pyenv virtualenv-init -)"

## Rbenv initialization 💎
#eval "$(rbenv init -)"

# 🎨 Oh My Zsh configuration

# Set the custom plugins directory
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Clone zsh-vi-mode plugin if not already present
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
    git clone https://github.com/jeffreytse/zsh-vi-mode.git "$ZSH_CUSTOM/plugins/zsh-vi-mode"
fi

# Clone zsh-autosuggestions plugin if not already present
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Clone zsh-syntax-highlighting plugin if not already present
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

ZSH_THEME="mira" # set by `omz`

## Plugins
plugins=(
    git
    zsh-vi-mode
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
    fzf
    flutter
)

source "$ZSH/oh-my-zsh.sh"

## zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Add zsh-syntax-highlighting at the end of the source list for proper loading
source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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

# 🎯 Dart CLI completion
[[ -f "$HOME/.dart-cli-completion/zsh-config.zsh" ]] && source "$HOME/.dart-cli-completion/zsh-config.zsh"

# NVM 
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f "$HOME/.dart-cli-completion/zsh-config.zsh" ]] && . "$HOME/.dart-cli-completion/zsh-config.zsh" || true
## [/Completion]


# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cool aliases
alias finger='adb -e emu finger touch 1 && adb -e emu finger remove 1'

alias ls="eza --icons=always"
alias vimconf="cd ~/.config/nvim/ && nvim ."

# tmux
alias tmux="tmux -f $HOME/.config/tmux/.tmux.conf"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
export PATH=$PATH:$HOME/go/bin
