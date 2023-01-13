# ERROR --> rgd:4: maximum nested function level reached; increase FUNCNEST?
# Need to be careful using aliases calling a function that calls another function/command inside it!!
# One solution is to quote the command inside the function
# reference: [bash - oh-my-zsh: git maximum nested function level reached - Stack Overflow](https://stackoverflow.com/a/70336970/9103915)

function rgd() {
  local search="$1"
  local location="$2"

  'rg' --smart-case --hidden --no-heading --column "$search" "$location" | awk -F ':' -f "$ZSH_CUSTOM/functions/colorize.awk"
}
