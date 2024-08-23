function envf() {
  local ENV_FILES=(.env*)

  [[ "${#ENV_FILES}" -eq "0" ]] && echo "No .env file was found!" && return 0

  local ENV_FILE="${1:-"${ENV_FILES[1]}"}"
  local ENV_UNCOMMENTED_FILE_CONTENT="$(grep '^[^#].*$' "$ENV_FILE")"

  local ENV_CHOICE="$(echo "$ENV_UNCOMMENTED_FILE_CONTENT" | sort -n | fzf --no-preview)"

  [[ -z $ENV_CHOICE ]] && return 0

  # local PATTERN='*="'
  # local REPLACE_STR="" # not needed but better to be explicit...

  # local ENV_VALUE=${ENV_CHOICE//${~PATTERN}/${REPLACE_STR}}

  # echo $ENV_VALUE
  # printf "%s"  ${ENV_VALUE:1:(${#ENV_VALUE} - 1)}

  ### Using `sed`
  # shellcheck disable=SC2001
  # local ENV_KEY="$(printf "%s" $ENV_CHOICE | sed -e 's/^\(.*=\).*$/\1/')"

  # ! does not work
  # local ENV_VALUE="$(printf "%s" $ENV_CHOICE | sed -e "s/^.*=[\",\']\?\(.*\)[\",\']\?$/\1/")"
  local ENV_VALUE="$(printf "%s" $ENV_CHOICE | sed -e "s/^.*=\"\([^\"].*\)\"|.*=\'\([^\'].*\)\'|.*=\(.*\)$/\1\2\3/")"

  printf "%s\n" "${ENV_VALUE}"
}

function envg() {
  # env is already an alias for:
  #   `env | sort -s`
  env | rg -i --no-line-number --no-column "$1"
}

function envx() {
  local cyan="${(%):-%F{cyan}"
  local reset="${(%):-%f}"
  local ENV_FILE

  [[ -z "$1" ]] && ENV_FILE=(.env*) || ENV_FILE=("$1")

  [[ "${#ENV_FILE[@]}" -eq "0" ]] && echo "No .env file was found!" && return 1

  local ENV_FILE_CONTENT=$(< ${ENV_FILE[1]})
  local ENV_KEYS="$(printf "%s" $ENV_FILE_CONTENT | sed -e 's/^\(.*=\).*$/\1/')"

  printf "%s" $ENV_KEYS > .env.example
  printf "\n%s\n\n" "$cyan""Copied to .env.example$reset"
  cat .env.example
}
