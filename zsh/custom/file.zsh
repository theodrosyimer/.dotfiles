function getExtension() {
  echo "${1##*.}"
}

# list all files and directories in current directory
# filter by using a glob pattern as argument
# i use this because ls 'separates filenames with newlines'
# see: [ParsingLs - Greg's Wiki](https://mywiki.wooledge.org/ParsingLs)
function list() {
  local paths=()
  for f in ${@:-*}; do
    if [[ -a $f ]]; then
      paths+="$(pwd)/$f";
      # continue
    fi
  done

  print -l $paths;
}

function listp() {
  local paths=()
  for f in ${@:-*}
    if [[ -a $f ]]; then
      parallel --shuf --eta -j+0 paths+="$(pwd)/$f";
    fi

  print -l $paths;
}

function get_basename_no_ext() {
  local path="${1:-$PWD}"
  echo "${${path:t}%%.*}"
}

function get_parent_dirname() {
  local path="${1:-$PWD}"
  echo "${path:h}"
}
