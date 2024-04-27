# source: https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

function tmux-sessionizer-fn() {
  if [[ $# -eq 1 ]]; then
      local selected=$1
  else
      local selected="$(find "${CODE_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d | fzf)"
  fi

  if [[ -z $selected ]]; then
      return 0
  fi

  local selected_name=$(basename "$selected" | tr . _)
  local tmux_running=$(pgrep tmux)

  if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
      tmux new-session -s "$selected_name" -c "$selected"
      return 0
  fi

  if ! tmux has-session -t="$selected_name" 2> /dev/null; then
      tmux new-session -ds "$selected_name" -c "$selected"
  fi

  tmux switch-client -t "$selected_name"
}
