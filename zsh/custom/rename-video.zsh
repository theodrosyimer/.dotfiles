function rename_videos_from_file() {
  local videos="$(find . -type f -iname "*.mp4" | sort)"
  local videos_array=(${(@f)videos})
  local titles="$(cat $1)"
  local titles_array=(${(@f)titles})

  mkdir -p renamed-videos &&
    for ((i=1; i < ${#videos_array[@]} + 1; i++)); do
        local title="$(trim "$titles_array[$i]")"
        local video="$(trim "$videos_array[$i]")"

        printf "%s\n" "Copied $video to renamed-videos/$title.mp4"

        if [[ -a "renamed-videos/$title.mp4" ]]; then
          printf "%s\n" "renamed-videos/$title.mp4 already exist skipping..."
          continue
        fi

        if [[ $i -lt 10 ]]; then
          cp "$video" "renamed-videos/0$i-$title.mp4"
        else
          cp "$video" "renamed-videos/$i-$title.mp4"
        fi
    done

}
