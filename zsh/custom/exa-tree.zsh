function lta() {
  'exa' -I node_modules ${3:=} --group-directories-first --header --git --long --tree --level=${2:=3} ${1:=.}
}

function lt() {
  'exa' -I node_modules ${3:=} --group-directories-first --tree --level=${2:=3} ${1:=.}
}
