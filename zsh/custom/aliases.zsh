# Safer default
alias cp='cp -i'
alias mv='mv -i'
alias rm='trash'

alias ez='exec zsh'
alias sz='source ~/.zshrc'

# Rust replacement for `cat`
alias cat='bat'

# Rust replacement for `ls`
alias ls='eza --sort=name --group --group-directories-first --header --git --icons'
alias l='ls -la'
alias ll='ls -l'
alias la='ls -laa'
alias lsd='ls -D'
alias ld='l -D'

alias t='tree_code'

alias vim=nvim
alias v=nvim
alias c='open -b com.microsoft.VSCode'
alias c.='c .'
alias cc='open -b com.todesktop.230313mzl4w4u92' # Cursor
alias cc.='cc .'

alias sd='fzf_code_projects'
# alias ccd='cc "$(eza --absolute $CODE_DIRS | fzf)" && z $_'
# alias ccd='cc "$(get_code_projects | fzf)" && z $_'

alias w='z $CODE_WORK'
alias p='z $CODE_PERSONAL'
alias o='z $CODE_PROJECTS/oss'
alias ref='z $CODE_REFS'
alias pc='z $CODE_PROJECTS'

alias ghc='gh pr create --web' # Create a new GitHub pull request (using GitHub CLI)
alias ghd='gh pr create -d'    # Create a new draft GitHub pull request (using GitHub CLI)
alias ghv='gh pr view --web'   # View a GitHub pull request (using GitHub CLI)
alias ghr='gh repo view --web' # View a GitHub repository (using GitHub CLI)

# alias gb="git branch --sort=-committerdate | fzf | xargs git checkout" # Checkout a Git branch (using fzf to select the branch interactively)
# alias gbr="git branch -r --sort=committerdate | sed 's/^[[:space:]]*[[:alnum:]_-]*\///' | grep -v 'HEAD ->' | fzf | xargs git checkout" # Checkout a remote Git branch (using fzf to select the branch interactively)
# alias gbd="git branch | fzf -m | xargs git branch -D" # Delete a Git branch (using fzf to select the branch interactively)
# alias gbdm="git branch --merged origin/main | grep -v 'main' | xargs git branch -d" # Delete a Git branch that is merged to main (using fzf to select the branch interactively)

# Package managers
alias pn='pnpm'
alias b='bun'
alias n='npm'
alias y='yarn'
alias nr='npm run'

# Interactive script selector with fzf and package manager runners
alias s="cat package.json | jq -r '.scripts | keys[]' | sort -r | fzf"
alias pm="cat package.json | jq -r '.packageManager // \"pnpm\"' | cut -d '@' -f1"
alias sr="s | xargs $(pm) run"
alias pns="s | xargs pnpm run"
alias ns="s | xargs npm run"
alias ys="s | xargs yarn run"

# Watch scripts
alias nw='node --watch'
alias bunw='bun --watch'
alias tscw='tsc --watch --noEmit'

# Docker
alias dcs='docker container stop $(docker container ps -aq)'
alias dcd='docker container rm $(docker container ps -aq)'

# tmux
alias tmuxcf='code ~/.tmux.conf'

# Pretty-print json on terminal
alias ppjson='python -m json.tool'

# Utilities
# Brew
alias bucud='brew update && brew upgrade && brew cleanup && brew doctor'

# use GNU's version of grep instead of BSD's version (macos default), see PATH in ~/.zshrc
alias grep='ggrep --color=auto'

# WORKING WITH FILES
# copy the working directory path
alias cpwd='pwd | tr -d "\n" | pbcopy'

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

# Custom scripts
alias mmdc='~/bin/mmd2cheatset.rb'

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
# alias ipg='lsof -nPi | rg -i'
# List opened TCP and UDP ips:ports
# alias ipls='lsof -nPi'

## FZF
# Search for zsh plugins with fzf
alias fzfz='fd ".+\.plugin\..+" $ZSH/plugins -x echo {/.} | sort | uniq | fzf --height 80% --border none --margin 10% --bind "?:toggle-preview" --preview "bat --color=always --style=numbers $ZSH/plugins/{}" --preview-window right,49% --nohidden'

# Search through my aliases with fzf
alias sa="bat $HOME/.dotfiles/zsh/custom/aliases.zsh | fzf --layout=reverse --border sharp --margin 5% --bind \"?:toggle-preview\" --preview \"rg -A 1 --smart-case --hidden --no-heading --column {} $HOME/.dotfiles/zsh/custom/aliases.zsh | bat --color=always --style=numbers $HOME/.dotfiles/zsh/custom/aliases.zsh\"  --preview-window nohidden"

# # Search through my aliases with fzf
# # can't feed the lines number to `bat`'s '`--line-range` option'
# alias sa='bat /Users/mac/.dotfiles/zsh/custom/aliases.zsh | fzf --layout=reverse --border sharp --margin 5% --bind "?:toggle-preview" --preview "rg -A 1 --smart-case --hidden --no-heading --column {} /Users/mac/.dotfiles/zsh/custom/aliases.zsh | cut -d : -f1 | rg "\d?\d?\d?\d?\d\d$" |bat --color=always --style=numbers --line-range {} /Users/mac/.dotfiles/zsh/custom/aliases.zsh"  --preview-window nohidden'

# List all tags
alias tls="tag -tgf \* | rg '^    ' | cut -c5- | sort -u --parallel 4"

# Delete all .DS_Store files recursively
alias rmds="fd -H --no-ignore '.DS_Store' -X /bin/rm"

# du default options: Get directory's contents size
alias du='du -hd 1'

alias cfv="code $DOTFILES/nvim/init.vim"
alias env='env | sort -s'

# npm-check-updates
alias ncu="ncu --configFileName .ncurc.json --configFilePath $DOTFILES/ncu"

# alias dk="docker"

# ETNA
# alias etna="ssh etna_piscine -p 22"

# Python3
# alias python=python3
# alias pip=pip3
alias py='python3'

alias lg='lazygit'

# rg setup to make the file open in default editor at the line number it's found at
alias rgc="rg --smart-case --hidden --no-heading --column --line-number -g '!package-lock.json' -g '!pnpm-lock.yaml' -g '!bun.lockb' -g '!.git'"

alias killbg='builtin kill -KILL'
alias loc='scc'

######### Expo #########
# Development Aliases
alias es='npx expo start'
alias esc='npx expo start --clear'
# Expo Build & Preview Aliases
alias ep='npx expo prebuild --clean'
alias epi='npx expo prebuild -p ios --clean'
alias epa='npx expo prebuild -p android --clean'

alias eri='npx expo run:ios'
alias era='npx expo run:android'
# EAS Build Aliases
alias ebdev='eas build:run --profile development'
alias ebprod='eas build:run --profile production'

# Android emulator appearance
alias aemdark="adb shell 'cmd uimode night yes'"
alias aemlight="adb shell 'cmd uimode night no'"
