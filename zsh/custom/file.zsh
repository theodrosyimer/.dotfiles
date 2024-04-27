alias dirsls="get_dirs_list"

function getExtension() {
  echo "${1##*.}"
  echo "${1:e}"
}

### Usage example
#
#   myarray=(${(f)$(get_dirs_list $HOME)[@]})
#
# code above is too cryptic...
# and we are making the work twice...
# better to inline code below when and where needed...
#   local paths=("${1:-"$PWD"}"/*)
#
# just replace the variables/arguments
# keeping it here for reference
function get_dirs_list() {
  local paths=("${1:-"$PWD"}"/*)
  printf "%s\n" ${#paths}
}

function get_basename_no_ext() {
  local path="${1:-$PWD}"
  echo "${${path:t}%%.*}"
}

function get_parent_dirname() {
  local path="${1:-$PWD}"
  echo "${path:h}"
}

function isRegularFileExist() {
  [[ -f "${1}" ]] && return 0 || return 1
}

function isFileEmpty() {
  [[ -s "${1}" ]] && return 1 || return 0
}

function prepend_text() {
  cat <<-EOF > ${PWD}/$2
$(printf '%s' "$1")
$(cat $2)
EOF
}
