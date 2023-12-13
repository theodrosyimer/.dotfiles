function _dev() {
local dir_list="$(find ${(s: :)CODE_DIRS} -mindepth 1 -maxdepth 1 -type d)"

fm "${dir_list[@]}"
}

zle -N _dev
bindkey -v
bindkey "^[f" _dev


function nt() {
  dir_list="$(find $NOTES -type f -regex ".*.md$" -mindepth 1 -maxdepth 1 | sort -r | fzf --preview "bat --color=always --style=numbers {}" \
    --bind "enter:execute("$EDITOR" {})+toggle-preview+accept" \
  )"
}
