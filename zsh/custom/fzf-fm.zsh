function fm() {
  local dir_list="${@:-"$PWD"}"

  # bind actions
  local find_videos="ctrl-f:reload(find {} -type f -iname \"*.mp4\")"
  local exit="esc:abort+close"
  local open_editor_or_mkdir="enter:accept-or-print-query"
  local go_to_selected_dir="ctrl-d:execute(echo {})+accept"
  local edit_path="ctrl-e:replace-query"
  local copy_in_current_dir="ctrl-i:execute-silent(cp -Ri {} .)+close"
  local go_back_start="ctrl-r:reload(echo \"$dir_list\")"
  local go_back_start_change_prompt="ctrl-r:+change-prompt()"
  local reload_ls="ctrl-c:reload(ls)"
  local open_finder="ctrl-o:execute(open -b "com.apple.finder" {})+close"

  local selected="$(echo "$dir_list" | sort --parallel=4 | uniq | \
    fzf \
    --bind "$find_videos" \
    --bind "$exit" \
    --bind "$go_to_selected_dir" \
    --bind "$open_editor_or_mkdir" \
    --bind "$edit_path" \
    --bind "$copy_in_current_dir" \
    --bind "$go_back_start" \
    --bind "$go_back_start_change_prompt" \
    --bind "$reload_ls" \
    --bind "$open_finder" \
    --preview-window hidden \
    )"

  if [[ -d "$selected" ]]; then
    "$EDITOR" "$selected" && z "$selected" && return 0
    # if [[ $2 == "-l" ]]; then
    #   echo "$selected"
    # fi
  fi

  if [[ -n "$selected" ]]; then
    mkdir -p "$selected" && z "$selected" && return 0
    # if [[ $2 == "-l" ]]; then
    #   echo "$selected"
    # fi
  fi

  return 0
}

# function fm_full() {
#   local dir_list="${@:-"$PWD"}"

#   # bind actions
#   local find_videos="ctrl-f:reload(find {} -type f -iname \"*.mp4\")"
#   local exit="esc:execute-silent()+close"
#   local got_to_selected_dir="ctrl-:execute(echo {})+accept"
#   local open_editor="enter:execute-silent("$EDITOR" {})+accept"
#   local copy_in_current_dir="ctrl-i:execute-silent(cp -Ri {} .)+close"
#   local go_back_start="ctrl-r:reload(echo \"$dir_list\")"
#   local go_back_start_change_prompt="ctrl-r:+change-prompt()"
#   local reload_ls="ctrl-c:reload(ls)"
#   local change_preview_toggle_preview="ctrl-p:+change-preview(exa --group-directories-first --tree --level=3 {} | head -50)"
#   local change_prompt_dirs="ctrl-d:change-prompt(Dirs > )"
#   local reload_dirs="ctrl-d:+reload(find {} -type d -mindepth 1 -maxdepth 1)"
#   local change_preview_toggle_preview_dirs="ctrl-d:+change-preview(exa --group-directories-first --tree --level=3 {} | head -50)"
#   local toggle_preview_dirs="ctrl-d:+toggle-preview"
#   local change_prompt_files="ctrl-f:change-prompt(Files > )"
#   local reload_files="ctrl-f:+reload(find {} -type f -mindepth 1 -maxdepth 1)"
#   local change_preview_toggle_preview_files="ctrl-f:+change-preview(bat --color=always --style=numbers {})"
#   local toggle_preview_files="ctrl-f:+toggle-preview"
#   local open_finder="ctrl-o:execute(open -b "com.apple.finder" {})+close"

#   local selected="$(echo "$dir_list" | \
#     fzf \
#     --bind "$find_videos" \
#     --bind "$exit" \
#     --bind "$got_to_selected_dir" \
#     --bind "$open_editor" \
#     --bind "$copy_in_current_dir" \
#     --bind "$go_back_start" \
#     --bind "$go_back_start_change_prompt" \
#     --bind "$reload_ls" \
#     --bind "$change_preview_toggle_preview" \
#     --bind "$change_prompt_dirs" \
#     --bind "$reload_dirs" \
#     --bind "$change_preview_toggle_preview_dirs" \
#     --bind "$toggle_preview_dirs" \
#     --bind "$change_prompt_files" \
#     --bind "$reload_files" \
#     --bind "$change_preview_toggle_preview_files" \
#     --bind "$toggle_preview_files" \
#     --bind "$open_finder" \
#     --preview-window hidden \
#     )"

#   if [[ -d "$selected" ]]; then
#     builtin cd "$selected" && return 0
#   fi

#   if [[ -f "$selected" ]]; then
#     open "$selected" && return 0
#   fi

#   return 0
# }
