# ! dependency to download: pandoc
# ! dependency: slugify.zsh -> available in the repository
function convert_md_html_from_cb() {
  local file_path="$(slugify ${1:-myfile})"
  local title="${2:-"This is the title of the file"}"

  echo -e "$(pbpaste)" | 'pandoc' -s --metadata title="$title" -f markdown_mmd -t html -o $file_path.html
}

# ! dependency to download: pandoc
# ! dependency: slugify.zsh -> available in the repository
function convert_md_man_from_cb() {
  local file_path="$(slugify ${1:-myfile})"
  local title="${2:-"This is the title of the file"}"

  echo -e "$(pbpaste)" | 'pandoc' -f markdown_mmd -t man -o $file_path.1
}
