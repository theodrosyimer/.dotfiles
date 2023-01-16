source $HOME/.dotfiles/zsh/.extras.zsh

export EDITOR='code'
# export VISUAL='code -n -w'
export VISUAL='nvim'

# zsh-vi-mode plugin
export ZVM_VI_EDITOR=$VISUAL
# export ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

export KEYTIMEOUT=1

export DOTNET_CLI_TELEMETRY_OPTOUT=true
export HOMEBREW_CASK_OPTS="--no-quarantine"
export HOMEBREW_NO_AUTO_UPDATE=1

# Need to be set because of completion problem
# -> repeat 2 first character when TAB to completion
# source: https://superuser.com/a/1738607
export LANG=en_US.UTF-8 # LANG=fr_FR.UTF-8

export RIPGREP_CONFIG_PATH="$DOTFILES/ripgrep/.ripgreprc"

FZF_COLORS="bg+:-1,\
fg:gray,\
fg+:white,\
border:black,\
spinner:0,\
hl:yellow,\
header:blue,\
info:green,\
pointer:red,\
marker:red,\
prompt:gray,\
hl+:red"

# fzf
export FZF_DEFAULT_COMMAND='rg --files \
--no-ignore \
--hidden \
--follow \
--glob "!.git/" --glob "!node_modules/" --glob "!.DS_Store" \
--sort path'
export FZF_DEFAULT_OPTS="--prompt=\"🔭 \" \
--prompt '∷ ' \
--pointer ▶ \
--marker ⇒
--height 80% \
--layout=reverse \
--border sharp \
--color="$FZF_COLORS"
--margin 5% \
--bind \"?:toggle-preview\" \
--preview 'bat --color=always --style=numbers {}'"

export FZF_CTRL_R_OPTS="--preview-window hidden"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {}'"

export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden -E node_modules'
export FZF_ALT_C_OPTS="--preview 'exa \
--group-directories-first \
--tree --level=3 {} | head -50'"
