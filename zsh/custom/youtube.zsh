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

# TODO: when yt-dl is not installed, add a prompt to ask if the user wants to download (and dependencies?)
function ytd() {
  local ERROR_MESSAGE=(
    "To install it manually ->$_cyan https://github.com/yt-dlp/yt-dlp/wiki/Installation#using-the-release-binary$_reset"
    )

  is_installed yt-dlp $ERROR_MESSAGE || return 1

  local DIRS_PATH="$(find $VIDEOS/coding $VIDEOS/coding/animation $VIDEOS/coding/css $VIDEOS/coding/drizzle $VIDEOS/coding/figma $VIDEOS/coding/git $VIDEOS/coding/javascript $VIDEOS/coding/python $VIDEOS/coding/sql "$VIDEOS/coding/Shell scripting with Bash and Zsh" -mindepth 1 -maxdepth 1 -type d)"

  local OUTPUT_PATH=("$(echo "${DIRS_PATH}" | fzf)")

echo $OUTPUT_PATH
  # local OUTPUT_PATH=("${PWD}")

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

  local YT_URL=("${1:-$(chrome_get_front_window_url)}")
  local REGEX='https://www.yout'

  [[ "$YT_URL" =~ "$REGEX" ]] || { \
    echo "$_red\nNo youtube video found on chrome's front tab.$_reset" && \
    return 1; }

  if [ -n "$FLAG_PLAYLIST" ]; then
    local YT_VIDEO_TITLE=$(chrome_get_front_window_title)

    [[ ! -d "$OUTPUT_PATH[-1]/$YT_VIDEO_TITLE" ]] && mkdir -p "$OUTPUT_PATH[-1]/$YT_VIDEO_TITLE"

    local OUTPUT_TEMPLATE='%(playlist_index)02d - %(title)s.%(ext)s'

    yt-dlp -f "$FORMAT" -o "$OUTPUT_PATH[-1]/$YT_VIDEO_TITLE/$OUTPUT_TEMPLATE" "$YT_URL[-1]" --progress --download-archive "$OUTPUT_PATH[-1]/$YT_VIDEO_TITLE/archive.txt" --restrict-filenames
    return $?
  else
    [[ ! -d "$OUTPUT_PATH[-1]" ]] && mkdir -p "$OUTPUT_PATH[-1]"

    local OUTPUT_TEMPLATE='%(title)s.%(ext)s'

    yt-dlp -f "$FORMAT" -o "$OUTPUT_PATH[-1]/$OUTPUT_TEMPLATE" "$YT_URL[-1]" --progress --restrict-filenames --no-playlist
    return $?
  fi
}
