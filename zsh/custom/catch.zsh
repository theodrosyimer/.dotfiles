# inspiration: https://www.shellscript.sh/exitcodes.html
function check_errs() {
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "[ ERROR ] # ${1} : ${2}"
    # as a bonus, make our script exit with the right error code.
    return ${1}
  fi
}

### `catch` function
#
# `$1` is the function to run
# `$2` is the custom error message to display on failure. (optional)
# if no custom error message is provided,
# then the error message is from the output of the function

function catch() {
  if [[ -z $2 ]]; then
    error_message=$($1 2>&1) || { \
    local exit_code="$?"
    printf >&2 "%b\n" \
    "$_red\n[ ERROR ]$_reset # "$_red$exit_code$_reset" : $_yellow$error_message$_reset" && \
    return "$exit_code"; }
  else
    $1 2>/dev/null 1>/dev/null || { \
    local exit_code="$?"
    printf >&2 "%b\n" \
    "$_red\n[ ERROR ]$_reset # "$_red$exit_code$_reset" : $_yellow${2}$_reset" && \
    return "$exit_code"; }
  fi
}

# catch false 'This is an error message'

# function hello() {
#   false;
#   printf >&2 "An error message from the function" && return 1
# }
# catch hello
# catch hello 'This is a custom error message'
