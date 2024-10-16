# Use to profile my shell performance,
# need to uncomment the last line of this file
# zmodload zsh/zprof

source ~/.zprofile

. /usr/local/etc/profile.d/z.sh

export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="kayid"

export ZSH_CUSTOM=$HOME/.dotfiles/zsh/custom

plugins=(
  brew
  git
  macos
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf-tab
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

# if [[ "$TERM_PROGRAM" == 'vscode' ]]; then
#   alias 'rg'='rgd'
# else
#   alias 'rg'='rg --smart-case --hidden --no-heading --color=always --column'
# fi

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
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# fpath=("${DOTFILES}/zsh/custom" "${fpath[@]}")
# autoload -Uz $fpath[1]/*(.:t)

# bun completions
[ -s "/Users/mac/.bun/_bun" ] && source "/Users/mac/.bun/_bun"

source ~/.iterm2_shell_integration.zsh

timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
eval "$(rbenv init -)"
eval "$(zoxide init zsh)"

# Load Angular CLI autocompletion.
source <(ng completion script)

# zprof


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
