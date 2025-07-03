# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

### $PATH is at the end to override any existing system-wide commands with mine
export PATH="$HOME/.fnm:$PATH"
export FNM_COREPACK_ENABLED=true

# Homebrew
# export PATH="/opt/homebrew/opt/*/bin:$PATH"

# Remove an annoying warning
export NODE_OPTIONS='--disable-warning=ExperimentalWarning'

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# MySQL@8.4
export PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/mysql@8.4/lib"
export CPPFLAGS="-I/opt/homebrew/opt/mysql@8.4/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql@8.4/lib/pkgconfig"

# MacPorts PATH
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# Java@17
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
# export PATH="/usr/local/opt/icu4c/sbin:$PATH"
# export PATH="/usr/local/opt/icu4c/bin:$PATH"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

### $PATH is at beginning to not accidently override any existing system-wide commands with mine
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/dev/tools/flutter/bin"

### Add my dirs to `$PATH`
export PATH="$PATH:$BIN"
export PATH="$PATH:$HOME/.js"

# Script Kit
export PATH="$PATH:$HOME/.kit/bin"
export PATH="$PATH:$HOME/.kenv/bin"
export PATH="$PATH:$HOME/.knode/bin"

### Paths i use for my automation
export DOTFILES="$HOME/.dotfiles"
export ZDOTDIR="$DOTFILES/zsh"
export BIN="$DOTFILES/bin"

# Karabiner
export GOKU_EDN_CONFIG_FILE="$DOTFILES/karabiner/karabiner.edn"

# Starship
export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"

export CODE="$HOME/dev"
export CODE_REFS="$CODE/refs"
export CODE_TEMPLATES="$CODE/templates"
export CODE_PROJECTS="$CODE/projects"
export CODE_PERSONAL="$CODE_PROJECTS/personal"
export CODE_COURSES="$CODE/courses"
export CODE_WORK="$CODE_PROJECTS/work"
export JS_SANDBOX="$CODE_REFS/js-sandbox"
export DOCSETS="$CODE_PERSONAL/mydocsets"
export TABLES="$CODE_PERSONAL/mytables"
export TAGS="$HOME/.my_tags"

export ICLOUD="$HOME/Library/Mobile Documents"
export MM="$ICLOUD/iCloud~com~toketaware~ios~ithoughts/Documents"

export ICLOUD_USER="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export ARTISTS_LIVE="$ICLOUD_USER/Artists (Live)"
export REFERENCES="$ICLOUD_USER/References"

export VSCODE_USER="$HOME/Library/Application Support/Code/User"

export DROPBOX="$HOME/Dropbox"
export NOTES="$DROPBOX/Notes"

export MUSIC="/Volumes/Audio-Production"
export ARTISTS="$MUSIC/Artistes"
export LPX="$MUSIC/Logic Pro X"
export LPX_COMPOS="$LPX/Compos"

export AUDIO_LIBRARIES="/Volumes/Librairies Samples"
export VIDEOS="$AUDIO_LIBRARIES/Videos"

export CODE_DIRS=("$CODE" "$CODE_PERSONAL" "$CODE_PERSONAL"/{assofac-projects,chatgpt-api,chrome-extensions,interviews,cli} "$CODE_WORK"/** "$CODE_WORK"/*/* "$CODE_WORK"/etna/** "$CODE_WORK/etna/bachelor"/** "$JS_SANDBOX"/* "$CODE_REFS" "$CODE_TEMPLATES" "$CODE_TEMPLATES/dev" "$CODE_TEMPLATES/dev/ts" "$CODE_TEMPLATES/dev/js" "$CODE_COURSES" "$DOTFILES" "$CODE/design" "$HOME")

eval "$(/opt/homebrew/bin/brew shellenv)"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"
