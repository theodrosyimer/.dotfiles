function _dev() {
  local dir_list="$(find "${CODE_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d)"

  fm "${dir_list[@]}"
}

zle -N _dev
bindkey -v
bindkey "^[f" _dev


function nt() {
  local dir_list="$(find $NOTES -type f -regex ".*.md$" -mindepth 1 -maxdepth 1 | sort -r --parallel 4 | fzf --preview "bat --color=always --style=numbers {}" \
    --bind "enter:execute("$EDITOR" {})+toggle-preview+accept" \
  )"
}

function videos() {
  local DIRS_PATHS=("$VIDEOS/coding" "$VIDEOS/coding/animation" "$VIDEOS/coding/css" "$VIDEOS/coding/drizzle" "$VIDEOS/coding/figma" "$VIDEOS/coding/git" "$VIDEOS/coding/javascript" "$VIDEOS/coding/python" "$VIDEOS/coding/sql" "$VIDEOS/coding/Shell scripting with Bash and Zsh")

  # local OUTPUT_PATH=("$(echo "${DIRS_PATHS}" | fzf --preview-window hidden)")

  local dir_list="$(find "${DIRS_PATHS[@]}" -mindepth 1 -maxdepth 2 -type d | sort -u --parallel 4)"

  fm "${dir_list[@]}"
}
