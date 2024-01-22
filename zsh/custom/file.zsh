alias dirsls="get_dirs_list_cwd"

function getExtension() {
  echo "${1##*.}"
  echo "${1:e}"
}

# list all files and directories in current directory
# filter by using a glob pattern as argument
# i use this because ls 'separates filenames with newlines'
# see: [ParsingLs - Greg's Wiki](https://mywiki.wooledge.org/ParsingLs)
function list() {
  local paths=()
  for f in *; do
    if [[ -a $f ]]; then
      paths+="$(pwd)/$f";
      # continue
    fi
  done

  print -l $paths;
}

function get_dirs_list_cwd() {
  local paths=""
  local input="${1:-"$PWD"}"
  local origin_cwd="$PWD"

  if [[ -n $input ]]; then
    echo $input
    cd "$input"
  fi

  for f in *; do
    if [[ -a $f ]]; then
      paths+="$(pwd)/$f\n";
      # continue
    fi
  done

  if [[ -n $input ]]; then
    echo $input
    cd $origin_cwd
  fi

  printf "%b" $paths;
}

# function get_dirs_list_cwd() {
#   local paths=""
#   local input=""

#   if [[ -n $1 ]]
#   then
#     input=$1/*
#   fi
#   echo $input

#   for f in $input; do
#     if [[ -a $f ]]; then
#       paths+="$(pwd)/$f\n";
#       # continue
#     fi
#   done

#   printf "%b" $paths;
# }

# function listp(){
#   local paths=()
#   for f in ${@:-*}
#     if [[ -a $f ]]; then
#       parallel --shuf -j+0 paths+={1} ::: "$f";
#     fi

#   print -l $paths;
# }

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
