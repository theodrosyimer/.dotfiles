alias psg="get_process"

function get_process() {
	ps aux | grep -v grep | extract_process_id "$1"
}

function extract_process_id() {
  # Check to see if a pipe exists on stdin.
  if [ -p /dev/stdin ]; then
    # echo "Data was piped to this script!"
    local pid_filter="$1"

    # If we want to read the input line by line
    # while IFS= read -r line; do
    #         echo "Line: $line"
    # done

    # Or if we want to simply grab all the data, we can simply use redirection or `cat` instead
    if [ -n "$pid_filter" ]; then
      awk -v pid="$pid_filter" '$2 == pid {print $1" "$2" "$11}' < /dev/stdin
    else
      awk '{print $1" "$2" "$11}' < /dev/stdin
    fi

  # Checking to ensure a filename was specified and that it exists
  elif [ -f "$1" ]; then
      # echo "Filename specified: $1"
      # echo "Doing things now.."
      local pid_filter="$2"
      if [ -n "$pid_filter" ]; then
        awk -v pid="$pid_filter" '$2 == pid {print $1" "$2" "$11}' < "$1"
      else
        awk '{print $1" "$2" "$11}' < "$1"
      fi

  # Checking to ensure an argument was specified and that it exists
  elif [ -n "$1" ]; then
      # echo "Argument specified: $1"
      local pid_filter="$2"
      if [ -n "$pid_filter" ]; then
        echo "$1" | awk -v pid="$pid_filter" '$2 == pid {print $1" "$2" "$11}'
      else
        echo "$1" | awk '{print $1" "$2" "$11}'
      fi
    else
      # echo "No input given!"
      return 1
  fi
}



