# Fetch YouTube transcript (auto-generated or manual) via yt-dlp
# Default output: clipboard (pbcopy)

function yt-transcript() {
  local ERROR_MESSAGE=(
    "To install it manually ->$CYAN https://github.com/yt-dlp/yt-dlp/wiki/Installation$RESET"
  )
  is_installed yt-dlp $ERROR_MESSAGE || return 1

  local VIDEO_URL FLAG_HELP OUTPUT_PATH
  local USAGE=(
    "yt-transcript [ -h | --help ]"
    "yt-transcript [ <video-url> ]"
    "yt-transcript [ <video-url> ] [ -o | --output <path> ]"
    ""
    "Default output: clipboard (pbcopy)"
    "Without a URL, grabs the active Chrome tab"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=FLAG_HELP \
    {o,-output}:=OUTPUT_PATH || return 1

  [[ -n "$FLAG_HELP" ]] && { print -l $USAGE && return; }

  # resolve URL: arg > Chrome front tab
  [[ -z "$1" ]] && VIDEO_URL="$(chrome_get_front_window_url)" || VIDEO_URL="$1"

  if ! _is_valid_url "$VIDEO_URL"; then
    printf "%s\n" "$RED\nInvalid URL or no supported video found in Chrome's front tab.$RESET"
    return 1
  fi

  local clean_url="${VIDEO_URL%%&t=*}"

  printf "%s\n" "Fetching transcript: $CYAN$clean_url$RESET" >&2

  # --- fetch metadata -------------------------------------------------------

  local channel title
  channel="$(yt-dlp --print channel --skip-download "$VIDEO_URL" 2>/dev/null)" || channel="Unknown"
  title="$(yt-dlp --print title --skip-download "$VIDEO_URL" 2>/dev/null)" || title="Unknown"

  # --- fetch subtitles ------------------------------------------------------

  local tmpdir="$(mktemp -d)"

  {
    # auto-subs first, fall back to manual
    if ! yt-dlp --write-auto-sub --sub-lang en --sub-format vtt \
                --skip-download -o "$tmpdir/sub" "$VIDEO_URL" 2>/dev/null; then
      if ! yt-dlp --write-sub --sub-lang en --sub-format vtt \
                  --skip-download -o "$tmpdir/sub" "$VIDEO_URL" 2>/dev/null; then
        printf "\n%s\n" "$RED""No English subtitles available for this video.$RESET"
        return 1
      fi
    fi

    local vtt_file="$(find "$tmpdir" -name '*.vtt' | head -1)"
    if [[ -z "$vtt_file" ]]; then
      printf "\n%s\n" "$RED""No subtitle file was downloaded.$RESET"
      return 1
    fi

    # --- parse VTT → plain transcript ----------------------------------------

    awk '
BEGIN { prev = "" }
/^WEBVTT/   { next }
/^Kind:/    { next }
/^Language:/{ next }
/^NOTE /    { next }
/^STYLE/    { next }
/^$/        { next }
/-->/       {
  split($1, t, ".")
  ts = t[1]
  next
}
{
  gsub(/<[^>]+>/, "")
  gsub(/^[ \t]+|[ \t]+$/, "")
  if ($0 == "") next
  if ($0 != prev) {
    if (ts != "") printf "%s %s\n", ts, $0
    else print
    prev = $0
  }
}
' "$vtt_file" > "$tmpdir/clean.txt"

    # --- assemble output ------------------------------------------------------

    local output
    output="$(printf 'YOUTUBE VIDEO TRANSCRIPT\n\n'
      printf 'CHANNEL: %s\n' "$channel"
      printf 'TITLE: %s\n' "$title"
      printf 'URL: %s\n\n' "$clean_url"
      cat "$tmpdir/clean.txt")"

    # --- write to file or clipboard -------------------------------------------

    if [[ -n "$OUTPUT_PATH" ]]; then
      local dest="${OUTPUT_PATH[-1]}"
      printf '%s\n' "$output" > "$dest"
      printf "\n%s\n" "$GREEN""Transcript written to: $CYAN$dest$RESET" >&2
    else
      printf '%s\n' "$output" | pbcopy
      printf "\n%s\n" "$GREEN""Transcript copied to clipboard$RESET ($title)" >&2
    fi

  } always {
    rm -rf "$tmpdir"
  }
}
