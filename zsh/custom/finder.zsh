function get_parent_dir_path_from_finder_selection() {
  osascript 2>/dev/null <<EOF
    tell application "Finder"
      return POSIX path of (target of window 1 as alias)
    end tell
EOF
}

#### As a command substitution, we must escape parentheses and use the `-e` option
# directory="$(osascript -e 2>/dev/null \
#    'tell application "Finder"
#      return POSIX path of (target of window 1 as alias)
#    end tell')"

function get_paths_from_finder_selection() {
  osascript 2>/dev/null <<EOF
    set output to ""
    tell application "Finder" to set the_selection to selection
    set item_count to count the_selection
    repeat with item_index from 1 to count the_selection
      if item_index is less than item_count then set the_delimiter to "\n"
      if item_index is item_count then set the_delimiter to ""
      set output to output & ((item item_index of the_selection as alias)'s POSIX path) & the_delimiter
    end repeat
EOF
}

#### As a command substitution, we must escape parentheses and use the `-e` option
# selection=$(osascript -e 2>/dev/null "set output to \"\"
#     tell application \"Finder\" to set the_selection to selection
#     set item_count to count the_selection
#     repeat with item_index from 1 to count the_selection
#       if item_index is less than item_count then set the_delimiter to \"\n\"
#       if item_index is item_count then set the_delimiter to \"\"
#       set output to output & ((item item_index of the_selection as alias)'s POSIX path) & the_delimiter
#     end repeat")"

function mvfd() {
	local paths=("$(get_paths_from_finder_selection)")
  local dirname=${paths[1]%%.*}

  mkdir -p $dirname
  mv $paths $dirname
}
