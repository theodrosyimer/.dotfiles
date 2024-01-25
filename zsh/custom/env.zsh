function envf() {
  local ENV_FILES=(.env*)

  [[ "${#ENV_FILES}" -eq "0" ]] && echo "No .env file was found!" && return 0

  local ENV_FILE=.env.local
  local ENV_FILE_CONTENT="$(grep '^[^#].*$' "$ENV_FILE")"
  local ENV_CHOICE="$(echo "$ENV_FILE_CONTENT" | sort -n | fzf)"

  local PATTERN='*="'
  local REPLACE_STR="" # not needed but better to be explicit...

  local RESULT=${ENV_CHOICE//${~PATTERN}/${REPLACE_STR}}
  printf "%s"  ${RESULT:0:(${#RESULT} - 1)}

  ### Using `sed`
  # shellcheck disable=SC2001
  # printf "%s" "$ENV_CHOICE" | sed -e "s/^.*=\"\(.*\)\"$/\1/"
}

function envg() {
  # env is already an alias for:
  #   `env | sort -s`
  env | rg -i --no-line-number --no-column "$1"

  # env | sort -s | rg -i --no-line-number --no-column "$1"
}

