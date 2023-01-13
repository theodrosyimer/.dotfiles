function _exec_zsh() {
  zle push-input
  BUFFER="exec zsh"
  zle accept-line
  zle clear-screen
}

zle -N _exec_zsh
bindkey -v
bindkey '^[e' _exec_zsh
