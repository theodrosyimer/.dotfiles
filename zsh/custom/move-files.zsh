function move_files() {
 	local files="$(fd -E '*.mp4' --base-directory "${1:-"${PWD}"}" -d 1)"

  echo "FILES \n$files"

  for file in "${(f)files}"; do
    # local dir_name="$(echo "${file}" | awk 'BEGIN {FS = "[0-9]{3} " } {print $1}')"
    echo "\nFILE\n$file"
    local dir_name="$(echo "${file}" > /dev/null | grep -ioE '^[0-9]{3}')"
    local dir_path="$PWD/${dir_name}"
    # local new_filename="$(echo "${file}" > /dev/null | awk 'BEGIN {FS = "[0-9]{3} " } {print $2}')"

    echo "DIR_PATH:\n$dir_path"
    # echo "NEW_FILENAME:\n$new_filename"


    if [[ -z "${dir_name}" ]]; then
      echo "'${file}' will not be moved because it does not match the pattern"
      continue
    fi

    if [[ ! -d "${dir_path}" ]]; then
      mkdir -p "${dir_name}"
    fi

    echo "SOURCE:\n$PWD/${file}"
    echo "DESTINATION:\n${dir_path}/${file}"

    mv "$PWD/${file}" "${dir_path}/${file}"
  done
}

function get_dirname_cwd(){
  local dirs

  for dir in *; do
    echo "$dir"
    dirs+="$dir\n"
  done

  echo "DIRS:\n$dirs"
}


function for_each_dir(){
  # local dirs="$(get_dirname_cwd)"

  for dir in *; do
    if [[ -d "${dir}" ]]; then
      cd "$dir" &&
        move_files &&
        cd ../
    fi
  done
}
