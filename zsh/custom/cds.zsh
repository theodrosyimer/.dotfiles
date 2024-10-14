# "fcd ~/Documents" goes there and lists the files with a preview
function fcd() {
  cd "$(find ${1:-.} -type d -mindepth 1 -maxdepth 1 | sort | fzf --preview "exa --tree {}")";
}
