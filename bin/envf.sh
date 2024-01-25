#!/usr/bin/env bash

ENV_FILES=(.env*)

[[ ${#ENV_FILES[@]} -eq "0" ]] && echo "No .env file was found" && return 1

ENV_FILE=.env
ENV_FILE_CONTENT="$(grep '^[^#].*$' "$ENV_FILE")"
ENV_CHOICE="$(echo "$ENV_FILE_CONTENT" | sort -n | fzf)"

PATTERN='*="'
REPLACE_STR="" # not needed but better to be explicit...

RESULT=${ENV_CHOICE/${PATTERN}/${REPLACE_STR}}
printf "%s" "${RESULT:0:(${#RESULT} - 1)}"

### Using `sed`
# shellcheck disable=SC2001
# printf "%s" "$ENV_CHOICE" | sed -e "s/^.*=\"\(.*\)\"$/\1/"
