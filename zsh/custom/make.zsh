function mkdocset() {
  docsets_path="$DOCSETS"
  filename="$1"

  cd "$docsets_path" &&
    mmd2cheatset "$docsets_path/$filename.md"
}

function mkn() {
  local extension=md
  local input_trimmed="$(trim $1)"
  local filename="$(spaced_by $input_trimmed ' ')"

  local output_path="${2:-"${NOTES:-"$(pwd)")}"}"

  zettID="$(zetid)"

  cd "$output_path" && echo "# $filename\n\n" >"$zettID $filename.$extension" && code -gn . "$zettID $filename.$extension":2
}

# TODO: create new file (reference) for a specified language
# sh, zsh, js, ts, py, rust, md
function mkref() {
  dir="${2:-"${CODE_REFS:-"$(pwd)"}"}"
  editor=code
  editor_args=-gn
  filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"
}

### * Create a new rust project and open it in vscode
# *
# * Usage:
# *
# * mkrustp <project_name>
# * mkrustp <path/to/project_name>
# *
function mkrustp() {
  project_name="$1"
  editor=code
  editor_args=-gn

  cargo new "$project_name" &&
    cd "$project_name" &&
    "$editor" "$editor_args" . src/main.rs
}

# TODO: add flag to switch between stdin and clipboard (mks and mksc)
function mks() {
  dir_path="${2:-"${BIN:-"$(pwd)"}"}"
  editor=code
  editor_args=-gn
  filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"

    echo -e "#!/usr/bin/env ${SHELL:t}\n\n" >$dir_path/$filename &&
    chmod u+x $dir_path/$filename &&
    $editor $editor_args "$dir_path" $dir_path/$filename:3
}

function mksc() {
  dir_path="${2:-"${BIN:-"$(pwd)"}"}"
  editor=code
  editor_args=-gn
  filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"
  content=$(pbpaste)

    printf "%b\n" "#!/usr/bin/env ${SHELL:t}\n\n$content" >"$dir_path/$filename" &&
    chmod u+x "$dir_path/$filename" &&
    $editor $editor_args "$dir_path" "$dir_path/$filename:3"
}

# TODO: add flag to switch between stdin and clipboard (mkzf and mkzfc)
function mkzf() {
  dir="$ZDOTDIR/custom"
  editor=code
  editor_args=-gn
  filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"
  funcname="$(echo $filename | sed s/-/_/g)"
  content="function $funcname() {\n\n}"

  cd $dir &&
    printf "%b\n" "$content" >$filename.zsh &&
    $editor $editor_args . $filename.zsh:2:3
}

function mkzfc() {
  dir="$ZDOTDIR/custom"
  editor=code
  editor_args=-gn
  filename="$(echo ${1:l} | sed -e 's/^ */-/g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"

  funcname="$(echo $filename | sed s/-/_/g)"
  content=$(pbpaste)

  cd $dir &&
    printf "%b\n" "function $funcname() {\n\t$content\n}" >$filename.zsh &&
    $editor $editor_args . $filename.zsh:1:10
}

function mkweb() {
  local default_path="$CODE_REFS/html-css"
  local flags_project_name=("my-project")
  local output_path=("${default_path}")
  local usage=(
    "mkweb [ -h | --help ]"
    "mkweb [ -n | --name <filename> ] [ -o | --output <path/to/directory> ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {n,--name}:=flags_project_name \
    {o,-output}:=output_path ||
    return 1

  [[ ! -z "$flag_help" ]] && { print -l $usage && return }

if [[ ! -z $flags_project_name ]]; then
  local project_name_formatted="$(echo ${flags_project_name[-1]:l} | sed s/" "/-/g)"

  if [[ -d "$output_path[-1]/$project_name_formatted" ]]; then
    echo -e "\nCreating $project_name_formatted project at $output_path[-1]/"

    cp -Rf /Users/mac/Code/_templates/dev/vanilla-html-css/ "$output_path[-1]/$project_name_formatted" &&
      cd "$output_path[-1]/$project_name_formatted" &&
      code -gn . src/index.html:17:5 src/* &&
      echo -e "\nDone!"
  fi

  if [[ ! -d "$output_path[-1]/$project_name_formatted" ]]; then
    echo -e "\nCreating $project_name_formatted project at $output_path[-1]/"

    mkdir -p "$output_path[-1]/$project_name_formatted" &&
      cp -Rf /Users/mac/Code/_templates/dev/vanilla-html-css/ "$output_path[-1]/$project_name_formatted" &&
      cd "$output_path[-1]/$project_name_formatted" &&
      code -gn . src/index.html:17:5 src/* &&
      echo -e "\nDone!"
  fi
fi
}
