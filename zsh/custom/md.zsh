alias mdhead=md_get_headers
alias mdheadi=md_get_headers_with_filename_and_lines
alias mdgoh=go_to_header

### Usage:
#
# markdown can be piped to the function:
#   `printf "%s" '#Test' | mdhead`
#
# as an argument:
#   `mdhead '#Test'`
#
# or a file path:
#   `mdhead '/path/to/file.md'`
#
function md_get_headers() {
  # Check to see if a pipe exists on stdin.
  if [ -p /dev/stdin ]; then
    printf "%s\n\n" "Data was piped to this script!"
    printf "%s\n\n" "Grabbing headers..."
	  grep '^[#].*$' < /dev/stdin

  # Checking to ensure a filename was specified and that it exists
  elif [ -f "$1" ]; then
      printf "%s\n\n" "Filename specified: $_purple$1$_reset"
      printf "%s\n\n" "Grabbing headers..."
      grep '^[#].*$' "$1" # < "$1"

  # Checking to ensure an argument was specified and that it exists
  elif [ -n "$1" ]; then
      printf "%s\n\n" "Argument specified: $1"
      printf "%s\n\n" "Grabbing headers..."
	    printf "%s" "$1" | grep '^[#].*$'

    else
      printf "%s\n" "No input given!"
  fi
}

function md_get_headers_with_filename_and_lines() {
  # Check to see if a pipe exists on stdin.
  if [ -p /dev/stdin ]; then
    printf "%s\n\n" "Data was piped to this script!"
    printf "%s\n\n" "Grabbing headers..."
	  grep -nH '^[#].*$' < /dev/stdin

  # Checking to ensure a filename was specified and that it exists
  elif [ -f "$1" ]; then
      printf "%s\n\n" "Filename specified: $1"
      printf "%s\n\n" "Grabbing headers..."
      grep -nH '^[#].*$' "$1" # < "$1"

  # Checking to ensure an argument was specified and that it exists
  elif [ -n "$1" ]; then
      printf "%s\n\n" "Argument specified: $1"
      printf "%s\n\n" "Grabbing headers..."
	    printf "%s" "$1" | grep -nH '^[#].*$'

    else
      printf "%s\n" "No input given!"
  fi
}

function go_to_header() {
  md_get_headers_with_filename_and_lines "$1" | fzf
}
