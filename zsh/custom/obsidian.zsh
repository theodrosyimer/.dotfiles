### Obsidian syntax:
# obsidian://action?param1=value&param2=value
# obsidian://open?vault=<vault>&file=<file>&section=<section>&edit=<edit>
# obsidian://advanced-uri?vault=<vault>&file=<file>&section=<section>&edit=<edit>&line=<line>&column=<column>&selection=<selection>&type=<type>

function obsidian_open() {
  if [[ -z "$1" ]]; then
    echo "Usage: obsidian_open <file>"
    return 1
  fi

  local file="$1"
  # local file_path="$NOTES/$file.md"
  local file_path="$file.md"

  # if [[ ! -f "$file_path" ]]; then
  #   echo "File $file_path does not exist"
  #   return 1
  # fi

local encoded_file_path="$(encode_uri_component "$file_path")"
  open "obsidian://$file_path"
}

alias obsd=obsidian_open
