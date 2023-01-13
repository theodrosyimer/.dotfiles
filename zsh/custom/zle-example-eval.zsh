function _zle_eval() {
  # echo -en "\e[2K\r"
  zle backward-kill-line
  echo "\r" #¯\_(ツ)_/¯
  eval "$@"
  echo "\r" #¯\_(ツ)_/¯
  zle redisplay
}
