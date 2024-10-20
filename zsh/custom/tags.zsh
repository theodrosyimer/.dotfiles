function tags_get_all_user_tags() {
  local current_dir=$(pwd)

  cd ~ &&
  'tag' -tgf \* | 'rg' '^    ' | 'cut' -c5- | 'sort' -u | 'rg' -N --no-column '^(:1:    )(.+)' -r $1 '$2' && cd "$current_dir"
}

function tags_write_to_file() {
  local default_path="$HOME/.my_tags"
  local file_path=${1:-${default_path}}
  tags_get_all_user_tags > "$file_path"
  la "$file_path"
}

function tags_show() {
  if [ ! -f $TAGS ]; then
    tags_write_to_file
  fi

  less $TAGS
}

function tags_get_total_count() {
  tags_show | wc -l
}

function tags_add_to_file() {
  local tags_selection="$(tags_show | fzf --multi)"
}

alias tags=tags_show
alias tagsc=tags_get_total_count
alias tagsw=tags_write_to_file
