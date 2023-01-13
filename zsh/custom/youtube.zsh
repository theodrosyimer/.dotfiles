# Format:
#
# see: https://github.com/yt-dlp/yt-dlp#format-selection
# see: https://github.com/yt-dlp/yt-dlp#filtering-formats
# see: https://github.com/yt-dlp/yt-dlp#sorting-formats
# see: https://github.com/yt-dlp/yt-dlp#format-selection-examples
#
# local format='(mp4)[height<=720]+bestaudio/best'
# local format='(mp4)[height<=1080]/best'
# local format='(mp4)[height<?1440]/best'
#
# Download the best mp4 video available, or the best video if no mp4 available
# shorthand for 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]':
# local format='bv[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv+ba/b'

# Output templates:
#
# see: https://github.com/yt-dlp/yt-dlp#output-template-examples
#
# Output templates for playlist:
#
# see: https://github.com/yt-dlp/yt-dlp#output-template-examples
# local output_template='%(playlist)s/%(playlist_index)02d - %(title)s.%(ext)s'
#
# using `--download-archive` option
# i can download only new videos from a playlist
# see: [How do I download only new videos from a playlist?](https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-download-only-new-videos-from-a-playlist)

# TODO: when yt-dl is not installed, add a prompt to ask if the user wants to download (and dependencies?)
function ytd() {
  local error_message=(
    "To install it manually ->$_cyan https://github.com/yt-dlp/yt-dlp/wiki/Installation#using-the-release-binary$_reset"
    )

  is_installed yt-dlp $error_message || return 1

  local source_url=("$(chrome_get_front_window_url)")
  local title=$(chrome_get_front_window_title)
  local output_path=("${PWD}")

  local format='bv[ext=mp4]+ba[ext=m4a]/b[ext=mp4] / bv+ba/b'
  local flag_playlist
  local usage=(
  "ytd [ -h | --help ]"
  "ytd [ -p | --playlist ] [ -o | --output <path/to/file> ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {s,-source}:=source_url \
    {p,-playlist}=flag_playlist \
    {o,-output}:=output_path || return 1

  [[ -n "$flag_help" ]] && { print -l $usage && return; }


  [[ $source_url =~ "https://www.yout" ]] || { \
    echo "$_red\nNo youtube video found on chrome's front tab.$_reset" && \
    return 1; }

  if [ -n "$flag_playlist" ]; then
    [[ ! -d "$output_path[-1]/$title" ]] && mkdir -p "$output_path[-1]/$title"

    local output_template='%(playlist_index)02d - %(title)s.%(ext)s'

    yt-dlp -f "$format" -o "$output_path[-1]/$title/$output_template" "$source_url[-1]" --progress --download-archive "$output_path[-1]/$title/archive.txt" --restrict-filenames
    return 0
  else
    [[ ! -d "$output_path[-1]" ]] && mkdir -p "$output_path[-1]"

    local output_template='%(title)s.%(ext)s'

    yt-dlp -f "$format" -o "$output_path[-1]/$output_template" "$source_url[-1]" --progress --restrict-filenames --no-playlist
    return 0
  fi

}
