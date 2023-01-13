# source: https://www.shellscript.sh/exitcodes.html
function check_errs() {
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "[ ERROR ] # ${1} : ${2}"
    # as a bonus, make our script exit with the right error code.
    return ${1}
  fi
}

# my version
function catch() {
  # `$1` is the function to run
  # `$2` is the error message to display on failure.
  $1 2>/dev/null 1>/dev/null || { \
  printf >&2 "%b\n" \
  "$_red\n[ ERROR ]$_reset # "$_red$?$_reset" : $_yellow${2}$_reset" && \
  return "$?"; }
}

# catch false 'This is an error message'
