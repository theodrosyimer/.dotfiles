function convert_yt_timestamps_to_mp4chaps() {
  while IFS="" read -r line || [ -n "$line" ]
  do
    printf "%s\n" "$line" | sed 's/- //g' >> 'timestamp.txt'
  done <<< "$1"
}

function convert_yt_timestamps_to_oggtext() {
  local count=1
  local line_formatted array timestamp title

  while IFS="" read -r line || [ -n "$line" ]
  do
    line_formatted="$(printf "%s" "$line" | sed 's/- //g')"
    timestamp=${line_formatted/% *}
    title=${line_formatted/#$timestamp }
    timestamp_line="CHAPTER0$count=$timestamp"
    title_line="CHAPTER0$count""NAME=$title"

    printf "%b\n" "$timestamp_line\n$title_line" >> 'timestamp_ogg.txt'

    count=$((count + 1))
  done <<< "$1"
}

# TODO: start to implement this function
function convert_yt_timestamps_to_m3U() {
  local count=1
  local line_formatted array timestamp title

  while IFS="" read -r line || [ -n "$line" ]
  do
    line_formatted="$(printf "%s" "$line" | sed 's/- //g')"
    timestamp=${line_formatted/% *}
    title=${line_formatted/#$timestamp }
    timestamp_line="CHAPTER0$count=$timestamp"
    title_line="CHAPTER0$count""NAME=$title"

    printf "%b\n" "$timestamp_line\n$title_line" >> 'timestamp_ogg.txt'

    count=$((count + 1))
  done <<< "$1"
}

alias yt_ts='convert_yt_timestamps_to_mp4chaps'
