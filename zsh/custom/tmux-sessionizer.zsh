# source: https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

function tmux_sessionizer_fn() {
  local selected
  if [[ $# -eq 1 ]]; then
      selected=$1
  else
      local dirs="$(find "${CODE_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d)"

      selected="$(fm "${dirs[@]}")"
      echo $selected
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

  tmux switch-client -t="$selected_name"
}

zle -N tmux_sessionizer_fn
bindkey -v
bindkey '^O' tmux_sessionizer_fn

alias tms=tmux_sessionizer_fn
