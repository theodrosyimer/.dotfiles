# Use to profile my shell performance,
# need to uncomment the last line of this file
# zmodload zsh/zprof

source ~/.zprofile

. /usr/local/etc/profile.d/z.sh

# source ~/.rbenv/completions/rbenv.zsh

export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="kayid"

ZSH_CUSTOM=$HOME/.dotfiles/zsh/custom


plugins=(
  brew
  git
  # golang
  macos
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
)

export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

source $ZSH/oh-my-zsh.sh

# User configuration

# 1Password completion
eval "$(op completion zsh)"
compdef _op op

# zsh-vi-mode plugin disabled the arrow behavior for history completion
# restore up/down arrow behavior
bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward

# bindkey '^\ ' autosuggest-clear

# edit current command line with vim (vim-mode, then CTRL-v)
# autoload -Uz edit-command-line
# zle -N edit-command-line
# bindkey -M vicmd '^v' edit-command-line

if [[ "$TERM_PROGRAM" == 'vscode' ]]; then
  alias 'rg'='rgd'
else
  alias 'rg'='rg --smart-case --hidden --no-heading --column'
fi

# WINDOW CONFIGURATION
################################################################################
#
# source: [zsh new line prompt after each command](https://stackoverflow.com/a/50103965/9103915)
case $TERM in
    *xterm*|*rxvt*|*screen*|*tmux*)
        function precmd() {
            # Print a newline before the prompt, unless it's the first
            # prompt in the parent process.
            if [ -z "${NEWLINE_BEFORE_PROMPT+x}" ]; then
                NEWLINE_BEFORE_PROMPT=1
            else
              printf "\n"
            fi
        }
esac

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# pnpm
export PNPM_HOME="/Users/mac/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# starship prompt
eval "$(starship init zsh)"

# zprof
