function mkl() {
  local input
  # check if there are any arguments otherwise use the clipboard
  if [[ -n $@ ]]; then
    input="$@"
  else
    input=$(pbpaste)
  fi

  echo "$@" | tr ' ' '\n'

}
