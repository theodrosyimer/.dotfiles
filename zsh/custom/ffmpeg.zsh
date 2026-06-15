function mp4copy() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: mp4copy <input-file> [output-file]"
    return 1
  fi

  local input="$1"
  local input_dir="${input:h}"
  local input_name="${input:t:r}"
  local output="${2:-${input_dir}/${input_name}.mp4}"

  if [[ ! -f "$input" ]]; then
    echo "Error: input file not found: $input"
    return 1
  fi

  ffmpeg -y -i "$input" \
    -c copy \
    -movflags +faststart \
    "$output"
}

function mov2mp4() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: mov2mp4 <input-file> [output-file]"
    return 1
  fi

  local input="$1"
  local input_dir="${input:h}"
  local input_name="${input:t:r}"
  local output="${2:-${input_dir}/${input_name}.mp4}"

  if [[ ! -f "$input" ]]; then
    echo "Error: input file not found: $input"
    return 1
  fi

  ffmpeg -y -i "$input" \
    -c:v libx264 \
    -preset slow \
    -crf 22 \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    "$output"
}

function mp4compatible() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: mp4compatible <mp4-file>"
    return 1
  fi

  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file"
    return 1
  fi

  local video_codec
  local audio_codec

  video_codec="$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file")"

  audio_codec="$(ffprobe -v error \
    -select_streams a:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file")"

  if [[ "$video_codec" != "h264" && "$video_codec" != "hevc" ]]; then
    return 1
  fi

  if [[ -n "$audio_codec" && "$audio_codec" != "aac" && "$audio_codec" != "mp3" ]]; then
    return 1
  fi

  return 0
}

function mp4auto() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: mp4auto <input-file> [output-file]"
    return 1
  fi

  local input="$1"
  local input_dir="${input:h}"
  local input_name="${input:t:r}"
  local output="${2:-${input_dir}/${input_name}.mp4}"
  local tmp_output="${output:r}.copy.mp4"

  if [[ ! -f "$input" ]]; then
    echo "Error: input file not found: $input"
    return 1
  fi

  echo "Trying lossless remux..."
  if mp4copy "$input" "$tmp_output" && mp4compatible "$tmp_output"; then
    mv "$tmp_output" "$output"
    echo "Done: compatible MP4 created without re-encoding."
    echo "$output"
    return 0
  fi

  echo "Remux failed or produced incompatible codecs."
  echo "Re-encoding to H.264/AAC..."

  rm -f "$tmp_output"

  mov2mp4 "$input" "$output"
}
