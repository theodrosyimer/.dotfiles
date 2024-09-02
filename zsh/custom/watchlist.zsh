alias wlc=create_watchlist_from_selected_dir

function create_watchlist_from_selected_dir() {
  local path="${1:-"$(get_paths_from_finder_selection)"}"
  local watchlist_name="${${path:t:l:gs/ /_/:gs/-//:gs/__/_/}%%.*}"
  local watchlist_path="$VIDEOS/watchlist/$watchlist_name.m3u8"

  if [ -f "${watchlist_path}" ]; then
    printf '%s\n' 'Watchlist updated'
    return 1
  fi

  printf '%s\n' "$path"/*.mp4 > "$watchlist_path"
  printf '%s\n' "Watchlist created -> $_cyan$watchlist_name$_reset"
}
