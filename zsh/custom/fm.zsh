function fm() {
  dir_list="${@:-"$PWD"}"

  # bind actions
  enter_dir="ctrl-f:reload(find {} -type f -iname \"*.mp4\")"

  selected="$(echo "$dir_list" | \
    fzf \
    --bind "$enter_dir" \
    --bind "enter:execute-silent(echo {})+accept" \
    --bind "ctrl-e:execute("$EDITOR" {})+close" \
    --bind "ctrl-i:execute-silent(cp -Ri {} .)+close" \
    --bind "ctrl-r:reload(echo \"$dir_list\")" \
    --bind "ctrl-c:reload(ls)" \
    --bind "ctrl-r:+change-preview(exa --group-directories-first --tree --level=3 {} | head -50)" \
    --bind "ctrl-r:+toggle-preview" \
    --bind "ctrl-d:change-prompt()" \
    --bind "ctrl-d:+reload(find {} -type d -mindepth 1 -maxdepth 1)" \
    --bind "ctrl-d:+change-preview(exa --group-directories-first --tree --level=3 {} | head -50)" \
    --bind "ctrl-d:+toggle-preview" \
    --bind "ctrl-f:change-prompt()" \
    --bind "ctrl-f:+reload(find {} -type f -mindepth 1 -maxdepth 1)" \
    --bind "ctrl-f:+change-preview(bat --color=always --style=numbers {})" \
    --bind "ctrl-f:+toggle-preview" \
    --bind "ctrl-o:execute(open -b "com.apple.finder" {})+close" \
    --preview-window hidden \
    )"

  # [[ -z "$selected" ]] && return 0

  if [[ -d "$selected" ]]; then
    echo "$selected"
    builtin cd "$selected" && return 0
  fi

  if [[ -f "$selected" ]]; then
    echo "$selected"
    open "$selected" && return 0
  fi

  return 0
}
