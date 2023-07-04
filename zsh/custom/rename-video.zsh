function rename_video() {
  local videos="$(find . -type f -iname "*.mp4")"
  local videos_array=(${(@f)videos})
  local titles="$(cat $1)"
  local titles_array=(${(@f)titles})

  mkdir -p renamed-videos &&
    for ((i=1; i < ${#videos_array[@]} + 1; i++)); do
        echo "Copied $videos_array[$i] to renamed-videos/$titles_array[$i].mp4"

        if [[ $i -lt 10 ]]; then
          cp "$videos_array[$i]" renamed-videos/"0$i-$titles_array[$i]".mp4
        else
          cp "$videos_array[$i]" renamed-videos/"$i-$titles_array[$i]".mp4
        fi
    done

}
