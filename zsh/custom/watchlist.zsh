function wla() {
  local maxdepth=1
  local path="$(get_paths_from_finder_selection)"
  local playlist_name="${${path:t:l:gs/ /_/:gs/-//:gs/__/_/}%%.*}"

  local videos_paths="$(find "$path" -type f -iname "*.mp4" -maxdepth $maxdepth)"
  # local videos_paths="$(fd -e mp4 --base-directory "$path" -d1)"


  echo "DIR_PATH:\n$path\n"
  echo "PLAYLIST_NAME:\n$playlist_name\n"
  echo "VIDEOS:\n$videos_paths"
  echo "$videos_paths" > "$VIDEOS/watchlist/$playlist_name.m3u8"
}
