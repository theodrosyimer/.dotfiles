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
export GOPATH="$HOME/Code/projects/go"
export PATH="$PATH:$GOPATH/bin"

# Paths i use for my automation
export DOTFILES="$HOME/.dotfiles"
export ZDOTDIR="$DOTFILES/zsh"
export BIN="$DOTFILES/bin"

# Add my scripts to `$PATH`
export PATH="$PATH:$BIN"
export PATH="$PATH:$HOME/.js"

# Script Kit
export PATH="$PATH:$HOME/.kit/bin"
export PATH="$PATH:$HOME/.kenv/bin"
export PATH="$PATH:$HOME/.knode/bin"


export CODE="$HOME/Code"
export CODE_PROJECTS="$CODE/projects"
export CODE_REFS="$CODE/refs"
export CODE_TEMPLATES="$CODE/_templates"
export JS_SANDBOX="$CODE_REFS/js/sandbox"
export DOCSETS="$CODE_PROJECTS/mydocsets"
export TABLES="$CODE_PROJECTS/mytables"
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

. "$HOME/.cargo/env"

eval "$(rbenv init -)"

eval "$(fnm env)"
# eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"

# brew auto-completion
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
