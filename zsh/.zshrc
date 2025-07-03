# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# Use to profile my shell performance,
# need to uncomment the last line of this file
# zmodload zsh/zprof

source ~/.zprofile

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

# zsh-vi-mode plugin disabled the arrow behavior for history completion
# restore up/down arrow behavior
bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward

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

source ~/.iterm2_shell_integration.zsh

# zsh-vi-mode
[ -f $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ] && source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

zvm_after_init_commands+=("[ -f $(brew --prefix)/opt/fzf/shell/key-bindings.zsh ] && source $(brew --prefix)/opt/fzf/shell/key-bindings.zsh")

autoload zmv

eval "$(starship init zsh)"
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
eval "$(rbenv init -)"
eval "$(pyenv init -)"
eval "$(zoxide init zsh)"

# 1Password completion
eval "$(op completion zsh)"
compdef _op op

# Angular CLI autocompletion.
source <(ng completion script)

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

. "$HOME/.cargo/env"

# brew auto-completion
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

if command -v symfony &>/dev/null; then
  eval "$(symfony completion)"
fi

# ngrok completion
if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# zprof

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/ty/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
