#!/usr/bin/env zsh

function codew() {
  local input=$*
  local ext="" # add a dot -> .txt
  local tmpfile=$(mktemp)

  if [[ -n $* ]]; then
    input="$*"
  else
    input=$(pbpaste)
  fi

  echo "$input" >"$tmpfile$ext"

  local text="$(code --wait --new-window --reuse-window "$tmpfile$ext" && cat "$tmpfile$ext")"

  echo "$text"

  rm "$tmpfile$ext"
}
