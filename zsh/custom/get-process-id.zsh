function get_process() {
	ps aux | grep -i "${1}" | grep -v grep | extract_process_id
}

function extract_process_id() {
  # Check to see if a pipe exists on stdin.
  if [ -p /dev/stdin ]; then
    # echo "Data was piped to this script!"

    # If we want to read the input line by line
    # while IFS= read -r line; do
    #         echo "Line: $line"
    # done

    # Or if we want to simply grab all the data, we can simply use redirection or `cat` instead
    awk '{print $1" "$2" "$11}' < /dev/stdin

  # Checking to ensure a filename was specified and that it exists
  elif [ -f "$1" ]; then
      echo "Filename specified: $1"
      echo "Doing things now.."
      awk '{print $1" "$2" "$11}' < "$1"

  # Checking to ensure an argument was specified and that it exists
  elif [ -n "$1" ]; then
      echo "Argument specified: $1"
      echo "$1" | awk '{print $1" "$2" "$11}'
    else
      echo "No input given!"
  fi
}



