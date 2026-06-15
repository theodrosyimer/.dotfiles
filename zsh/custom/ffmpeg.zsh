# MP4 conversion helpers
#
# Main command:
#
#   mp4auto <input-file> [output-file]
#
# `mp4auto` runs the full automatic workflow:
#
#   1. Inspects the input file with ffprobe.
#   2. Checks whether the input codecs are already broadly MP4-compatible.
#   3. If compatible, tries a lossless remux using ffmpeg -c copy.
#   4. Verifies the produced MP4 with ffprobe.
#   5. If remux fails or the result is incompatible, automatically re-encodes to H.264/AAC.
#
# In normal use, run only:
#
#   mp4auto video.mov
#
# Examples:
#
#   mp4auto video.mov
#   mp4auto ~/Downloads/video.mov
#   mp4auto video.mov final.mp4
#
# Default output:
#
#   If no output file is provided, the converted file is created next to the input file
#   using the ".converted.mp4" suffix.
#
#   Example:
#
#     ~/Downloads/video.mov -> ~/Downloads/video.converted.mp4
#
# Helper commands:
#
#   `mp4copy`
#     Lossless remux only. Fast, no quality loss, but only works when codecs are MP4-compatible.
#
#   `mov2mp4`
#     Re-encodes to H.264/AAC. Slower and lossy, but broadly compatible.
#
#   `mp4compatible_input`
#     Checks whether an input file looks suitable for remuxing to MP4.
#
#   `mp4compatible`
#     Checks whether an existing MP4 has broadly compatible codecs.
#
# Requirements:
#
#   `ffmpeg`
#   `ffprobe`
#
# Notes:
#
#   This does not convert literally every possible file.
#   It works for most video files that your FFmpeg installation can decode.
#   DRM-protected, corrupted, or unsupported files may fail.
#
#   CRF 22 is visually good for most use cases but is not lossless.
#   The lossless path is mp4copy/remux, not mov2mp4/re-encode.

function mp4copy() {
  if [[ $# -lt 1 ]]; then
    printf "\n%b\n" "Usage: mp4copy <input-file> [output-file]"
    return 1
  fi

  local input="$1"
  local input_dir="${input:h}"
  local input_name="${input:t:r}"
  local output="${2:-${input_dir}/${input_name}.converted.mp4}"

  if [[ ! -f "$input" ]]; then
    printf "\n%b\n" "$RED""Error: input file not found: $input""$RESET"
    return 1
  fi

  ffmpeg -y -i "$input" \
    -c copy \
    -movflags +faststart \
    "$output"
}

function mov2mp4() {
  if [[ $# -lt 1 ]]; then
    printf "\n%b\n" "Usage: mov2mp4 <input-file> [output-file]"
    return 1
  fi

  local input="$1"
  local input_dir="${input:h}"
  local input_name="${input:t:r}"
  local output="${2:-${input_dir}/${input_name}.converted.mp4}"

  if [[ ! -f "$input" ]]; then
    printf "\n%b\n" "$RED""Error: input file not found: $input""$RESET"
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

function mp4compatible_input() {
  if [[ $# -lt 1 ]]; then
    printf "\n%b\n" "Usage: mp4compatible_input <input-file>"
    return 1
  fi

  local file="$1"

  if [[ ! -f "$file" ]]; then
    printf "\n%b\n" "$RED""Error: file not found: $file""$RESET"
    return 1
  fi

  local video_codec
  local audio_codec
  local pixel_format

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

  pixel_format="$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=pix_fmt \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file")"

  if [[ "$video_codec" != "h264" && "$video_codec" != "hevc" ]]; then
    return 1
  fi

  if [[ "$pixel_format" != "yuv420p" && "$pixel_format" != "yuvj420p" ]]; then
    return 1
  fi

  if [[ -n "$audio_codec" && "$audio_codec" != "aac" && "$audio_codec" != "mp3" ]]; then
    return 1
  fi

  return 0
}

function mp4compatible() {
  if [[ $# -lt 1 ]]; then
    printf "\n%b\n" "Usage: mp4compatible <mp4-file>"
    return 1
  fi

  local file="$1"

  if [[ ! -f "$file" ]]; then
    printf "\n%b\n" "$RED""Error: file not found: $file""$RESET"
    return 1
  fi

  local video_codec
  local audio_codec
  local pixel_format

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

  pixel_format="$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=pix_fmt \
    -of default=noprint_wrappers=1:nokey=1 \
    "$file")"

  if [[ "$video_codec" != "h264" && "$video_codec" != "hevc" ]]; then
    return 1
  fi

  if [[ "$pixel_format" != "yuv420p" && "$pixel_format" != "yuvj420p" ]]; then
    return 1
  fi

  if [[ -n "$audio_codec" && "$audio_codec" != "aac" && "$audio_codec" != "mp3" ]]; then
    return 1
  fi

  return 0
}

function mp4auto() {
  if [[ $# -lt 1 ]]; then
    printf "\n%b\n" "Usage: mp4auto <input-file> [output-file]"
    return 1
  fi

  local input="$1"
  local input_dir="${input:h}"
  local input_name="${input:t:r}"
  local output="${2:-${input_dir}/${input_name}.converted.mp4}"
  local tmp_output="${output:r}.copy.mp4"

  if [[ ! -f "$input" ]]; then
    printf "\n%b\n" "$RED""Error: input file not found: $input""$RESET"
    return 1
  fi

  if mp4compatible_input "$input"; then
    printf "\n%b\n\n" "$GREEN""Input looks MP4-compatible. Trying lossless remux...""$RESET"

    if mp4copy "$input" "$tmp_output" && mp4compatible "$tmp_output"; then
      mv "$tmp_output" "$output"
      printf "\n%b\n" "$GREEN""Done: compatible MP4 created without re-encoding.""$RESET"
      printf "%b\n" "Output: $output"
      return 0
    fi

    printf "\n%b\n" "$YELLOW""Remux failed despite compatible-looking input.""$RESET"
    rm -f "$tmp_output"
  else
    printf "\n%b\n" "$YELLOW""Input codecs are not broadly MP4-compatible.""$RESET"
  fi

  printf "%b\n" "$GREEN""Re-encoding to H.264/AAC...""$RESET"

  mov2mp4 "$input" "$output"
}
