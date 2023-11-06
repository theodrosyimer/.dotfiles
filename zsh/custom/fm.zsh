function fm() {
  dir_list="${@}"

  # bind actions
  open_finder="ctrl-o:execute-silent(open -b "com.apple.finder" {})+close"
  enter_dir="ctrl-f:reload(find {} -type f -iname \"*.mp4\")"

  selected="$(echo "$dir_list" | \
    fzf \
    --bind "$enter_dir" \
    --bind "enter:execute-silent(echo {})+accept" \
    --bind "ctrl-c:execute-silent("$EDITOR" {})+accept" \
    --bind "ctrl-i:execute(cp -Ri {} .)+accept" \
    --bind "ctrl-r:reload(echo \"$dir_list\")" \
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
    --bind "$open_finder" \
    --preview-window hidden)"
}
