function _auto_sudo() {
  local BUFFER="sudo $BUFFER"
  local CURSOR=$#BUFFER
  zle end-of-line
}

zle -N _auto_sudo
bindkey -v
bindkey "^[x" _auto_sudo
