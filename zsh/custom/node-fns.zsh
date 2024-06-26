# These functions only works with `zsh`!

alias nasync='test_async_execution_order'
alias nctx='print_global_context'
alias nenv='print_node_env'
alias nenvg='grep_node_env'

# Dependencies:
# `fzf` (for some options of the script but not -c (--compare) option )
# ./colorize.zsh (in that directory)
function test_async_execution_order() {
  # To get the most of this script:
  # you need to clone the repo https://github.com/nearform/promises-workshop
  # to get the executed promises :
  # git clone https://github.com/nearform/promises-workshop
  #
  # or grab just the relevant files:
  # promises-workshop/exercises/section1/order/first.mjs
  # promises-workshop/exercises/section1/order/second.mjs
  # promises-workshop/exercises/section1/order/first.js
  # promises-workshop/exercises/section1/order/second.js
  #

  # Then update this path to the parent directory of the repo
  local MY_PATH="$JS_SANDBOX"

  local ESM_FILE_PATH="$MY_PATH/promises-workshop/exercises/section1/order/first.mjs"
  local ESM_CALLBACK_FILE_PATH="$MY_PATH/promises-workshop/exercises/section1/order/second.mjs"
  local CJS_FILE_PATH="$MY_PATH/promises-workshop/exercises/section1/order/first.js"
  local CJS_CALLBACK_FILE_PATH="$MY_PATH/promises-workshop/exercises/section1/order/second.js"

  local flag_help flag_esm flag_commonjs flag_callback flag_compare
  local js_to_execute
  local usage=(
  "nasync [ -e | --esm ] - Default option"
  "nasync [ -cjs | --commonjs ]"
  "nasync [ -cb | --callback ]"
  "nasync [ -c | --compare ]"
  "nasync [ -h | --help ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {e,-esm}=flag_esm \
    {cjs,-commonjs}=flag_commonjs \
    {cb,-callback}=flag_callback \
    {c,-compare}=flag_compare || return 1

  [[ -n "$flag_help" ]] && { print -l $usage && return; }

  [[ -n "$flag_compare" ]] && { print_compare && return; }

  # default to esm if no flag is passed
  if [[ -z "$flag_esm" && -z "$flag_commonjs" ]]; then
      js_to_execute="$ESM_FILE_PATH"
      # default to esm if just `$flag_callback` flag is passed
      if [[ -n "$flag_callback" ]]; then
        js_to_execute="$ESM_CALLBACK_FILE_PATH"
      fi
  elif [[ -n "$flag_commonjs" ]]; then
    js_to_execute="$CJS_FILE_PATH"
    if [[ -n "$flag_callback" ]]; then
      js_to_execute="$CJS_CALLBACK_FILE_PATH"
    fi
  elif [[ -n "$flag_esm" ]]; then
    js_to_execute="$ESM_FILE_PATH"
    if [[ -n "$flag_callback" ]]; then
      js_to_execute="$ESM_CALLBACK_FILE_PATH"
    fi
  fi

  printf "%b" "\tExecution order starting from $([[ -z $flag_callback ]] && echo 'GLOBAL context' || echo "the EVENT LOOP's queueMicroTask") in a $([[ -z $flag_commonjs ]]  && echo 'ESM' || echo 'CommonJS') file."

  local result="$(node $js_to_execute)"
  echo "$result" | fzf \
  --height=99% \
  --preview-window=right,80% \
  --preview "bat $js_to_execute --color=always --file-name=${js_to_execute:t} --style=header-filename,grid --line-range=:100 --theme='Monokai Extended'"

  # echo "$result" | fzf --multi --preview 'echo {} | xargs -I{} node /Users/mac/Code/refs/js-sandbox/promises-workshop/exercises/section1/order/first.js {}'
}

# Dependency:
# `jq`
function print_global_context() {
  node --no-warnings -e 'console.log(JSON.stringify(Object.keys(global)))' | jq -r '.[]' | sort | uniq
}

# Dependency:
# `jq`
function print_node_env() {
  node --no-warnings -e 'console.log(JSON.stringify(process.env))' | jq -r '.' | sort | uniq
}

# Dependency:
# `print_node_env` function above
function grep_node_env() {
  print_node_env | grep -i $1
}

# Dependency:
# ./colorize
function print_compare() {
  printf "%s\n" "
               "$_purple"ESM$_reset                                       "$_purple"COMMONJS$_reset
    "$_yellow"GLOBAL$_reset      |      "$_yellow"CALLBACK$_reset                 "$_yellow"GLOBAL$_reset      |      "$_yellow"CALLBACK$_reset
  new promise       new promise         |     new promise       new promise
  async function    async function      |     async function    async function
  "$_cyan"then 1$_reset            nextTick 1          |     nextTick 1        nextTick 1
  "$_cyan"then 2$_reset            nextTick 2          |     nextTick 2        nextTick 2
  "$_cyan"microtask 1$_reset       nextTick 3          |     nextTick 3        nextTick 3
  "$_cyan"microtask 2$_reset       "$_cyan"then 1$_reset              |     then 1            then 1
  nextTick 1        "$_cyan"then 2$_reset              |     then 2            then 2
  nextTick 2        "$_cyan"microtask 1$_reset         |     microtask 1       microtask 1
  nextTick 3        "$_cyan"microtask 2$_reset         |     microtask 2       microtask 2
  immediate 1       immediate 1         |     "$_cyan"timeout 1$_reset         immediate 1
  immediate 2       immediate 2         |     "$_cyan"timeout 2$_reset         immediate 2
  timeout 1         timeout 1           |     immediate 1       "$_cyan"timeout 1$_reset
  timeout 2         timeout 2           |     immediate 2       "$_cyan"timeout 2$_reset
  "
}
