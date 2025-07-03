source $HOME/.dotfiles/zsh/.extras.zsh

export EDITOR='cursor'
# export VISUAL='code -n -w'
export VISUAL='nvim'

# zsh-vi-mode plugin
export ZVM_VI_EDITOR=$VISUAL
# export ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

export KEYTIMEOUT=1

export DOTNET_CLI_TELEMETRY_OPTOUT=true
export STORYBOOK_DISABLE_TELEMETRY=1
export HOMEBREW_CASK_OPTS="--no-quarantine"
export HOMEBREW_NO_AUTO_UPDATE=1

export LC_COLLATE=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_TIME=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# Need to be set because of completion problem
# -> repeat 2 first character when TAB to completion
# source: https://superuser.com/a/1738607
export LANG=en_US.UTF-8 # LANG=fr_FR.UTF-8
export LANGUAGE=en_US.UTF-8
export LESSCHARSET=utf-8

# Man pages
export MANPAGER='nvim --cmd ":lua vim.g.noplugins=1" +Man!'
export MANWIDTH=999

export RIPGREP_CONFIG_PATH="$HOME/.dotfiles/ripgrep/.ripgreprc"

# fzf
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

export FZF_DEFAULT_COMMAND='rg --files \
--no-ignore \
--hidden \
--follow \
--glob "!.git/objects/" --glob "!.git/logs/" --glob "!node_modules/" --glob "!.DS_Store" \
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
--bind \"ctrl-e:execute("$EDITOR" {})+toggle-preview+accept\" \
--bind \"ctrl-o:execute(open -b \"com.apple.finder\" {})+toggle-preview+accept\" \
--preview '[[ -f {} ]] && bat --color=always --style=numbers {}'"

export FZF_CTRL_R_OPTS="--preview-window hidden"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {}'"

export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden -E ".git/objects/" -E ".git/logs/" -E node_modules'

export FZF_ALT_C_OPTS="--preview 'exa \
--group-directories-first \
--tree --level=3 {} | head -50'"

# debugging zsh
export DEBUG_ZSH_LOAD_TIME=""

# zoxide
# _ZO_DATA_DIR=""

# _ZO_ECHO=1

_ZO_EXCLUDE_DIRS=""

_ZO_FZF_OPTS="$FZF_DEFAULT_OPTS"

_ZO_RESOLVE_SYMLINKS=1
