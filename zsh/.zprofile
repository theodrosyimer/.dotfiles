export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

# $PATH is at the end to override any existing system-wide commands with mine
export PATH="$HOME/.fnm:$PATH"
# export PATH="/usr/local/bin/python3:$PATH"
# export PATH="/usr/local/bin/rbenv:$PATH"
export PATH="/usr/local/opt/sqlite/bin:$PATH"
export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export PATH="/usr/local/opt/icu4c/bin:$PATH"

# $PATH is at beginning to not accidently override any existing system-wide commands with mine
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/Code/tools/flutter/bin"


# Paths i use for my automation
export DOTFILES="$HOME/.dotfiles"
export ZDOTDIR="$DOTFILES/zsh"
export BIN="$DOTFILES/bin"

# Starship
export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"

# Add my scripts to `$PATH`
export PATH="$PATH:$BIN"
export PATH="$PATH:$HOME/.js"

# Script Kit
export PATH="$PATH:$HOME/.kit/bin"
export PATH="$PATH:$HOME/.kenv/bin"
export PATH="$PATH:$HOME/.knode/bin"

export MANPAGER='nvim --cmd ":lua vim.g.noplugins=1" +Man!'
export MANWIDTH=999

export CODE="$HOME/Code"
export CODE_REFS="$CODE/refs"
export CODE_TEMPLATES="$CODE/templates"
export CODE_PROJECTS="$CODE/projects"
export CODE_PERSONAL="$CODE_PROJECTS/personal"
export CODE_COURSES="$CODE_PROJECTS/courses"
export CODE_WORK="$CODE_PROJECTS/work"
export JS_SANDBOX="$CODE_REFS/js-sandbox"
export DOCSETS="$CODE_PERSONAL/mydocsets"
export TABLES="$CODE_PERSONAL/mytables"
export TAG_LIST="$HOME/.my_tags"

export ICLOUD="$HOME/Library/Mobile Documents"
export MM="$ICLOUD/iCloud~com~toketaware~ios~ithoughts/Documents"

export ICLOUD_USER="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export ARTISTS_LIVE="$ICLOUD_USER/Artists (Live)"
export REFERENCES="$ICLOUD_USER/References"

export DROPBOX="$HOME/Dropbox"
export NOTES="$DROPBOX/Notes"

export MUSIC="/Volumes/Audio-Production"
export ARTISTS="$MUSIC/Artistes"
export LPX="$MUSIC/Logic Pro X"
export LPX_COMPOS="$LPX/Compos"

export AUDIO_LIBRARIES="/Volumes/Librairies Samples"
export VIDEOS="$AUDIO_LIBRARIES/Videos"

export CODE_DIRS="$CODE $CODE_PERSONAL $CODE_WORK $JS_SANDBOX $CODE_REFS $CODE_TEMPLATES $CODE_TEMPLATES/dev $CODE_TEMPLATES/dev/ts $CODE_TEMPLATES/dev/js $CODE_COURSES $DOTFILES $HOME/Design $HOME"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.cargo/env"

eval "$(rbenv init -)"

eval "$(fnm env)"
# eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

# brew auto-completion
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

