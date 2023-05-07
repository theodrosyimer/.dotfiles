function mkdocset() {
  docsets_path="$DOCSETS"
  filename="$1"

  cd "$docsets_path" &&
    mmd2cheatset "$docsets_path/$filename.md"
}

function mkn() {
  local editor=code
  local extension=md
  local input_trimmed="$(trim $1)"
  local filename="$(spaced_by $input_trimmed ' ')"

  local output_path="${2:-"${NOTES:-"$(pwd)")}"}"

  [[ -f "$output_path/$filename.zsh" ]] && { \
    echo -e "\nFile already exists at $output_path/$filename.zsh" && $editor "$output_path/$filename.zsh" && return 1; }

  zettID="$(zetid)"

  cd "$output_path" && echo "# $filename\n\n" >"$zettID $filename.$extension" && code -g . "$zettID $filename.$extension":2
}

# TODO: create new file (reference) for a specified language
# sh, zsh, js, ts, py, rust, md
function mkref() {
  local output_path="${2:-"${CODE_REFS:-"$(pwd)"}"}"
  local editor=code
  local editor_args=-g
  local filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"
}

### * Create a new rust project and open it in vscode
# *
# * Usage:
# *
# * mkrustp <project_name>
# * mkrustp <path/to/project_name>
# *
function mkrustp() {
  local project_name="$1"
  local editor=code
  local editor_args=-gn

  [[ -d "$project_name" ]] && { \
    echo -e "\nFile already exists at $project_name\n" && $editor "$project_name" && return 1; }

  cargo new "$project_name" &&
    cd "$project_name" &&
    "$editor" "$editor_args" . src/main.rs
}

# TODO: add flag to switch between stdin and clipboard (mks and mksc)
function mks() {
  local output_path="${2:-"${BIN:-"$(pwd)"}"}"
  local editor=code
  local editor_args=-g
  local filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"

  [[ -f "$output_path/$filename" ]] && { \
    echo -e "\nFile already exists at $output_path/$filename" && $editor "$output_path/$filename" && return 1; }

    echo -e "#!/usr/bin/env ${SHELL:t}\n\n" >$output_path/$filename &&
    chmod u+x $output_path/$filename &&
    $editor $editor_args "$output_path/$filename:3"
}

function mksc() {
  local output_path="${2:-"${BIN:-"$(pwd)"}"}"
  local editor=code
  local editor_args=-g
  local filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"
  local content=$(pbpaste)

  [[ -f "$output_path/$filename" ]] && { \
    echo -e "\nFile already exists at $output_path/$filename" && $editor "$output_path/$filename" && return 1; }

    printf "%b\n" "#!/usr/bin/env ${SHELL:t}\n\n$content" >"$output_path/$filename" &&
    chmod u+x "$output_path/$filename" &&
    $editor $editor_args "$output_path/$filename:3"
}

# TODO: add flag to switch between stdin and clipboard (mkzf and mkzfc)
function mkzf() {
  local root_dir="${DOTFILES}"
  local my_functions_dir="$ZDOTDIR/custom"
  local output_path="${2:-"${my_functions_dir:-"$(pwd)"}"}"
  local editor=code
  local editor_args=-g
  local filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"
  local funcname="$(echo $filename | sed s/-/_/g)"
  local content="function $funcname() {\n\n}"

  [[ -f "$output_path/$filename.zsh" ]] && { \
    echo -e "\nFile already exists at $output_path/$filename.zsh" && $editor "$output_path/$filename.zsh" && return 1; }

  printf "%b\n" "$content" >"$output_path/$filename.zsh" &&
  $editor $editor_args "$output_path/$filename.zsh":2:3
}

function mkzfc() {
  local root_dir="${DOTFILES}"
  local my_functions_dir="$ZDOTDIR/custom"
  local output_path="${2:-"${my_functions_dir:-"$(pwd)"}"}"
  local editor=code
  local editor_args=-g
  local filename="$(echo ${1:l} | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g' -e 's/ /-/g')"

  local funcname="$(echo $filename | sed s/-/_/g)"
  local content=$(pbpaste)

  [[ -f "$output_path/$filename.zsh" ]] && { \
    echo -e "\nFile already exists at $output_path/$filename.zsh" && $editor "$output_path/$filename.zsh" && return 1; }

  printf "%b\n" "function $funcname() {\n\t$content\n}" >"$output_path/$filename.zsh" &&
  $editor $editor_args "$output_path/$filename.zsh":1:10
}

function mkweb() {
  local js_template_path=/Users/mac/Code/_templates/dev/js/vanilla-html-css/
  local ts_template_path=/Users/mac/Code/_templates/dev/ts/vanilla-ts/
  local css_template_path=/Users/mac/Code/_templates/dev/css/style.css

  local default_path="$CODE_REFS/html-css"
  local project_name="${1:-"my-project"}"
  local output_path=("${default_path:-"$(pwd)"}")
  local usage=(
    "mkweb [ -h | --help ]"
    "mkweb [ -n | --name <filename> ] [ -o | --output <path/to/directory> ]"
  )

  local flag_typescript flag_help

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {ts,-typescript}=flag_typescript \
    {o,-output}:=output_path || return 1

  [[ ! -z "$flag_help" ]] && { print -l $usage && return; }

  # slugify input
  local project_name_formatted="$(echo ${project_name:l} | sed -e 's/ /-/g')"

  # if output path does exist, inform user and exit
  if [[ -d "$output_path[-1]/$project_name_formatted" ]]; then
    echo -e "\nDirectory \"$project_name_formatted\" already exists at $output_path[-1]/$project_name_formatted" &&
      $editor "$output_path[-1]/$project_name_formatted" &&
      return 1
  fi

  # if output path does not exist, create it
  if [[ ! -d "$output_path[-1]/$project_name_formatted" ]]; then
    echo -e "\nCreating $project_name_formatted project at $output_path[-1]/"

    mkdir -p "$output_path[-1]/$project_name_formatted" &&
      # copy template files to new project directory
      cp -Rf "$js_template_path" "$output_path[-1]/$project_name_formatted" &&
      # copy my css reset to new project directory
      cp -f "$css_template_path" "$output_path[-1]/$project_name_formatted/src" &&
      cd "$output_path[-1]/$project_name_formatted" &&
      npm pkg set 'name'="$project_name_formatted" &&
      echo -e "\nDone!"

      echo -e "\nRunning:\n"
      echo -e "  pnpm install:latest"

      pnpm install:latest &&
        echo -e " pnpm dev\n" &&
        code -gn . src/index.html:18:7 src/* vite.config.js &&
        pnpm dev

  fi
}
