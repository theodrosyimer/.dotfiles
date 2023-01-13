#!/usr/bin/env sh

# This version is compatible with bash

# input=$@
ext=md
tmpfile=$(mktemp)
input="${*:-"$(pbpaste)"}"

printf "%s\n" "$input" >"$tmpfile".$ext
open -a /Applications/iThoughtsX.localized/iThoughtsX.app "$tmpfile".$ext
rm "$tmpfile".$ext
