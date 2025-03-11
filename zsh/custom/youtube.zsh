# FORMAT:
#
# see: https://github.com/yt-dlp/yt-dlp#FORMAT-selection
# see: https://github.com/yt-dlp/yt-dlp#filtering-FORMATs
# see: https://github.com/yt-dlp/yt-dlp#sorting-FORMATs
# see: https://github.com/yt-dlp/yt-dlp#FORMAT-selection-examples
#
# local FORMAT='(mp4)[height<=720]+bestaudio/best'
# local FORMAT='(mp4)[height<=1080]/best'
# local FORMAT='(mp4)[height<?1440]/best'
#
# Download the best mp4 video available, or the best video if no mp4 available
# shorthand for 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]':
# local FORMAT='bv[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv+ba/b'

# Output templates:
#
# see: https://github.com/yt-dlp/yt-dlp#output-template-examples
#
# Output templates for playlist:
#
# see: https://github.com/yt-dlp/yt-dlp#output-template-examples
# local OUTPUT_TEMPLATE='%(playlist)s/%(playlist_index)02d - %(title)s.%(ext)s'
#
# using `--download-archive` option
# i can download only new videos from a playlist
# see: [How do I download only new videos from a playlist?](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-download-only-new-videos-from-a-playlist)

# Helper function to get available video directories
function _get_video_dirs() {
  # Default to Movies directory if VIDEOS is not set
  local default_dir="$HOME/Movies"
  local base_dir="${VIDEOS:-$default_dir}"

  # If VIDEOS is set, use its subdirectories, otherwise use default_dir
  if [[ -n "$VIDEOS" ]]; then
    local base_dirs=(
      "$VIDEOS"
      "$VIDEOS/coding"
      "$VIDEOS/coding/animation"
      "$VIDEOS/coding/css"
      "$VIDEOS/coding/drizzle"
      "$VIDEOS/coding/figma"
      "$VIDEOS/coding/git"
      "$VIDEOS/coding/javascript"
      "$VIDEOS/coding/python"
      "$VIDEOS/coding/sql"
      "$VIDEOS/coding/Shell scripting with Bash and Zsh"
    )
  else
    local base_dirs=("$default_dir")
  fi

  # Find all directories in the specified paths, suppressing errors
  local dirs_path="$(find "${base_dirs[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sort -u --parallel 4)"

  # If no directories found, use base directory
  if [ -z "$dirs_path" ]; then
    dirs_path="$base_dir"
  fi

  echo "$dirs_path"
}

# Helper function to validate YouTube URL
function _is_valid_youtube_url() {
  local url="$1"
  local patterns=(
    '^https?://(www\.)?youtube\.com/watch\?v=[a-zA-Z0-9_-]+'
    '^https?://(www\.)?youtu\.be/[a-zA-Z0-9_-]+'
    '^https?://(www\.)?youtube\.com/playlist\?list=[a-zA-Z0-9_-]+'
  )

  for pattern in "${patterns[@]}"; do
    if [[ "$url" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# Helper function to sanitize URL
function _sanitize_url() {
  local url="$1"
  # Remove any URL parameters after the video ID
  url="${url%%&*}"
  echo "$url"
}

# TODO: when yt-dl is not installed, add a prompt to ask if the user wants to download (and dependencies?)
function ytd() {
  local ERROR_MESSAGE=(
    "To install it manually ->$_cyan https://github.com/yt-dlp/yt-dlp/wiki/Installation#using-the-release-binary$_reset"
    )

  is_installed yt-dlp $ERROR_MESSAGE || return 1

  local OUTPUT_PATH=()
  local YT_URL
  local FORMAT='bv[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv+ba/b'
  local FLAG_PLAYLIST FLAG_HELP
  local USAGE=(
    "ytd [ -h | --help ]"
    "ytd [ <youtube-video-url> ]"
    "ytd [ <youtube-video-url> ] [ -p | --playlist ] [ -o | --output <path/to/file> ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=FLAG_HELP \
    {p,-playlist}=FLAG_PLAYLIST \
    {o,-output}:=OUTPUT_PATH || return 1

  [[ -n "$FLAG_HELP" ]] && { print -l $USAGE && return; }

  [[ -z "$1" ]] && YT_URL="$(chrome_get_front_window_url)" || YT_URL="$1"

  # Sanitize and validate YouTube URL
  YT_URL="$(_sanitize_url "$YT_URL")"
  if ! _is_valid_youtube_url "$YT_URL"; then
    printf "%s\n" "$_red\nInvalid YouTube URL or no YouTube video found in chrome's front tab.$_reset"
    return 1
  fi

  printf "%s\n" "Downloading: $_cyan$YT_URL$_reset"

  # Handle output path selection
  if [[ "$#OUTPUT_PATH" -eq 0 ]]; then
    local dirs_path="$(_get_video_dirs)"
    local selected_path="$(fm "${dirs_path}")"

    # Check if fm command returned a valid path
    if [[ -n "$selected_path" && -d "$selected_path" ]]; then
      OUTPUT_PATH=("$selected_path")
    else
      OUTPUT_PATH=("${PWD}")
    fi
  fi

  # Ensure output directory exists
  if [[ ! -d "$OUTPUT_PATH[-1]" ]]; then
    if ! mkdir -p "$OUTPUT_PATH[-1]"; then
      printf "%s\n" "$_red\nFailed to create output directory: $OUTPUT_PATH[-1]$_reset"
      return 1
    fi
  fi

  if [ -n "$FLAG_PLAYLIST" ]; then
    local YT_VIDEO_TITLE=$(chrome_get_front_window_title)
    local playlist_dir="$OUTPUT_PATH[-1]/$YT_VIDEO_TITLE"

    # Create playlist directory
    if [[ ! -d "$playlist_dir" ]]; then
      if ! mkdir -p "$playlist_dir"; then
        printf "%s\n" "$_red\nFailed to create playlist directory: $playlist_dir$_reset"
        return 1
      fi
    fi

    local OUTPUT_TEMPLATE='%(playlist_index)02d - %(title)s.%(ext)s'
    yt-dlp -f "$FORMAT" \
           -o "$playlist_dir/$OUTPUT_TEMPLATE" \
           "$YT_URL" \
           --progress \
           --download-archive "$playlist_dir/archive.txt" \
           --restrict-filenames
  else
    local OUTPUT_TEMPLATE='%(title)s.%(ext)s'
    yt-dlp -f "$FORMAT" \
           -o "$OUTPUT_PATH[-1]/$OUTPUT_TEMPLATE" \
           "$YT_URL" \
           --progress \
           --restrict-filenames \
           --no-playlist
  fi

  return $?
}
