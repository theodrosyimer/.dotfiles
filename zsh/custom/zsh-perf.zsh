function zsh_boot() {
  for i in {1..10}; do /usr/bin/time zsh -i -c exit; done
}

function zsh_debug_info() {
  local debug="$($(which zsh) -lxv)"
  echo $debug >"$HOME/Desktop/zsh-boot-debug.txt"
}

function zsh_debug_info2() {
  zsh -i -c -x exit
}
