function get_basename_no_ext() {
  local current_dir="${1:-$PWD}"
  # local path_basename=$(basename $current_dir)
  local basename_no_ext="${${current_dir:t}%.*}"

  # echo ${path_basename%.*}
  echo $basename_no_ext
}
