#!/usr/bin/env zsh

function codew() {
  local input=$*
  local ext=".zsh" # add a dot -> .txt
  local tmpfile=$(mktemp)

  [[ $EDITOR == "code" ]] || [[ $EDITOR == "cursor" ]] || return 1

  if [[ -n $* ]]; then
    input="$*"
  else
    input=$(pbpaste)
  fi

  echo "$input" > "$tmpfile$ext"

  local text="$($EDITOR --wait --new-window --reuse-window "$tmpfile$ext" && cat "$tmpfile$ext")"

  echo "$text"

  rm "$tmpfile$ext"
}
