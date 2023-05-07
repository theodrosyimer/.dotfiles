function getExtension() {
  echo "${1##*.}"
}

# list all files and directories in current directory
# filter by using a glob pattern as argument
# i use this because ls 'separates filenames with newlines'
# see: [ParsingLs - Greg's Wiki](https://mywiki.wooledge.org/ParsingLs)
function list() {
  for f in ${@:-*}; do
    echo "$(pwd)/$f";
  done
}

function get_basename_no_ext() {
  local current_dir="${1:-$PWD}"
  # local path_basename=$(basename $current_dir)
  local basename_no_ext="${${current_dir:t}%.*}"

  # echo ${path_basename%.*}
  echo $basename_no_ext
}

function get_parent_dirname() {
  local current_dir="${1:-$PWD}"

  # echo "$(dirname $current_dir)"
  echo "${current_dir:h}"
}
