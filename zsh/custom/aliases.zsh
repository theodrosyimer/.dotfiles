#autoload

# Safer default
alias cp="cp -i"
alias mv="mv -i"
alias rm="trash"

alias sz='source ~/.zshrc'
alias sb='source ~/.bash_profile'

# open current directory in Finder
alias od="open-directory"

# Text-Editor
alias vim=nvim
alias v=vim
alias c='code'
alias cc='code .'

# Rust replacement for `cat`
alias cat='bat'

# to align `clear` with ^-l keystroke behavior
# that is modified by my .zshrc
# ! it doesn't work', find a solution
alias cl="unset NEW_LINE_BEFORE_PROMPT && clear"

# Rust replacement for `ls`
alias ls='exa --sort=name --group --group-directories-first --header --git'
# alias lsa='ls -la'
alias l='ls -la'
alias ll='ls -l'
alias la='ls -laa'
alias lsd='ls -D'
alias ld='l -D'

# SSH
# alias sadd='ssh-add -K &>/dev/null'

# tmux
alias tmuxcf='code ~/.tmux.conf'

# Pretty-print json on terminal
alias ppjson="python -m json.tool"

# Utilities
# Brew
alias bucud='brew update && brew upgrade && brew cleanup && brew doctor'

# use GNU's version of grep instead of BSD's version (macos default), see PATH in ~/.zshrc
alias grep='ggrep --color=auto'

# WORKING WITH FILES
# copy the working directory path
alias cpwd='pwd|tr -d "\n"|pbcopy'

# Hidden files in Finder
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'

alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

# Get current external IP
alias ip="curl icanhazip.com"

# Dock commands
alias statdock='defaults write com.apple.dock static-only -bool true; killall Dock'
alias fixdock='defaults write com.apple.dock static-only -bool false; killall Dock'

# NPM
alias npmlg='npm ls -g --depth 0' # Get NPM modules' list used globally

# Python3
alias python=python3
alias pip=pip3

# Custom scripts
alias mmdc='~/bin/mmd2cheatset.rb'

# Open VLC cli ?
alias vlc='/Applications/VLC.app/Contents/MacOS/VLC'

# Open Chrome/Chromium cli
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias chrome-canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"
alias chromium="/Applications/Chromium.app/Contents/MacOS/Chromium"

# Get front tab's url & title
# alias chromeUrl='/Users/mac/.dotfiles/zsh/chromeUrl'
# alias chromeTitle='/Users/mac/.dotfiles/zsh/chromeTitle'

# System
# top
alias cpu='top -o cpu'
alias mem='top -o rsize' # memory

# Hide files passed into it
alias cfh='chflags hidden'
alias cfnh='chflags nohidden'

# Display folder storage
alias usage='du -h -d1'

# Check a given port is opened (syntax `:PORT``)
alias runp='lsof -i '

## FZF
# Search for zsh plugins with fzf
alias fzfz='fd ".+\.plugin\..+" $ZSH/plugins -x echo {/.} | sort | uniq | fzf --height 80% --border none --margin 10% --bind "?:toggle-preview" --preview "bat --color=always --style=numbers $ZSH/plugins/{}" --preview-window right,49% nohidden'

# Search through my aliases with fzf
alias sa='bat /Users/mac/.dotfiles/zsh/custom/aliases.zsh | fzf --layout=reverse --border sharp --margin 5% --bind "?:toggle-preview" --preview "rg -A 1 --smart-case --hidden --no-heading --column {} /Users/mac/.dotfiles/zsh/custom/aliases.zsh | bat --color=always --style=numbers /Users/mac/.dotfiles/zsh/custom/aliases.zsh"  --preview-window nohidden'

# # Search through my aliases with fzf
# # can't feed the lines number to `bat`'s '`--line-range` option'
# alias sa='bat /Users/mac/.dotfiles/zsh/custom/aliases.zsh | fzf --layout=reverse --border sharp --margin 5% --bind "?:toggle-preview" --preview "rg -A 1 --smart-case --hidden --no-heading --column {} /Users/mac/.dotfiles/zsh/custom/aliases.zsh | cut -d : -f1 | rg "\d?\d?\d?\d?\d\d$" |bat --color=always --style=numbers --line-range {} /Users/mac/.dotfiles/zsh/custom/aliases.zsh"  --preview-window nohidden'

# List all tags
alias tls="tag -tgf \* | rg '^    ' | cut -c5- | sort -u"

# Delete all .DS_Store files recursively
alias rmds="fd -H '^\.DS_Store$' -X rm"

# du default options: Get directory's contents size
alias du="du -hd 1"

alias cfv="code $DOTFILES/nvim/init.vim"
