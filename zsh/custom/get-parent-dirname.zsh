function get_parent_dirname() {
  local current_dir="${1:-$PWD}"

  # echo "$(dirname $current_dir)"
  echo "${current_dir:h}"
}
