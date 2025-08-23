function fm() {
  local dir_list="${@:-"$PWD"}"

  # bind actions
  local find_videos="ctrl-f:reload(find {} -type f -iname \"*.mp4\")"
  local exit="esc:execute-silent()+close"
  local got_to_selected_dir="ctrl-space:execute(echo {})+accept"
  local open_editor="enter:execute-silent("$EDITOR" {})+accept"
  local copy_in_current_dir="ctrl-i:execute-silent(cp -Ri {} .)+close"
  local go_back_start="ctrl-r:reload(echo \"$dir_list\")"
  local go_back_start_change_prompt="ctrl-r:+change-prompt()"
  local reload_ls="ctrl-c:reload(ls)"
  local change_preview_toggle_preview="ctrl-p:+change-preview(exa --group-directories-first --tree --level=3 {} | head -50)"
  local change_prompt_dirs="ctrl-d:change-prompt(Dirs > )"
  local reload_dirs="ctrl-d:+reload(find {} -type d -mindepth 1 -maxdepth 1)"
  local change_preview_toggle_preview_dirs="ctrl-d:+change-preview(exa --group-directories-first --tree --level=3 {} | head -50)"
  local toggle_preview_dirs="ctrl-d:+toggle-preview"
  local change_prompt_files="ctrl-f:change-prompt(Files > )"
  local reload_files="ctrl-f:+reload(find {} -type f -mindepth 1 -maxdepth 1)"
  local change_preview_toggle_preview_files="ctrl-f:+change-preview(bat --color=always --style=numbers {})"
  local toggle_preview_files="ctrl-f:+toggle-preview"
  local open_finder_ctrl_o="ctrl-o:execute(open -b "com.apple.finder" {})+close"

  local selected="$(echo "$dir_list" | \
    fzf \
    --bind "$find_videos" \
    --bind "$exit" \
    --bind "$got_to_selected_dir" \
    --bind "$open_editor" \
    --bind "$copy_in_current_dir" \
    --bind "$go_back_start" \
    --bind "$go_back_start_change_prompt" \
    --bind "$reload_ls" \
    --bind "$change_preview_toggle_preview" \
    --bind "$change_prompt_dirs" \
    --bind "$reload_dirs" \
    --bind "$change_preview_toggle_preview_dirs" \
    --bind "$toggle_preview_dirs" \
    --bind "$change_prompt_files" \
    --bind "$reload_files" \
    --bind "$change_preview_toggle_preview_files" \
    --bind "$toggle_preview_files" \
    --bind "$open_finder_ctrl_o" \
    --preview-window hidden \
    )"

  if [[ -d "$selected" ]]; then
    builtin cd "$selected" && return 0
  fi

  if [[ -f "$selected" ]]; then
    open "$selected" && return 0
  fi

  return 0
}
