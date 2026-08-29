# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Environment variables
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

export RUBY_CFLAGS="-Wno-error=implicit-function-declaration"
if [[ -d /opt/homebrew/opt/openjdk@17 ]]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
elif /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
fi

# Path modifications
export PATH="$HOME/.redscripts:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/opt:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="/usr/local/share/dotnet:$PATH"
export PATH="$HOME/.pyenv/bin:$PATH"

export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_HOME="/opt/homebrew/share/android-ndk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:$PATH"

export PATH="$HOME/fvm/default/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"
export PATH="/opt/homebrew/opt/mbedtls@2/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
export PATH="$HOME/Applications/Qt/6.6.3/macos/bin:$PATH"
export PATH="/Applications/Android Studio.app/Contents/MacOS:$PATH"
export PATH="/Library/Frameworks/GStreamer.framework/Commands:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"

# Other environment variables
export PKG_CONFIG_PATH="/opt/homebrew/opt/curl/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/expat/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/Library/Frameworks/GStreamer.framework/Versions/1.0/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/Library/Frameworks/GStreamer.framework/Versions/1.0/lib/gstreamer-1.0/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"

export LDFLAGS="-L/opt/homebrew/opt/libffi/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libffi/include"
export ZSH="$HOME/.oh-my-zsh"
export CASE_SENSITIVE="false"
export Qt5_DIR="/opt/homebrew/opt/qt@5/lib/cmake/Qt5"
export NVM_DIR="$HOME/.nvm"

