# source: [Passing a parameter to a zsh keyboard-shortcut - DEV Community](https://dev.to/ecologic/passing-a-parameter-to-a-zsh-keyboard-shortcut-1877)
function _buffer() {
  local buffer=$BUFFER
  local args=(${(@s:,:)buffer})

  zle backward-kill-line
  echo "$args[1]" "$args[2]" "$args[3]"
  echo "\n" #¯\_(ツ)_/¯
  # zle reset-prompt
  # zle redisplay
  zle clear-screen
}

# zle -N _buffer
# bindkey '^ff' _buffer
