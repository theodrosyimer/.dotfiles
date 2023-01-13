#!/usr/bin/env zsh

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
