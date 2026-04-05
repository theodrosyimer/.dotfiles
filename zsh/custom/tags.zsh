function tags_get_all_user_tags() {
  local current_dir=$(pwd)

  cd ~ &&
  'tag' -tgf \* | 'rg' '^    ' | 'cut' -c5- | 'sort' -u && cd "$current_dir"
  # 'tag' -tgf \* | 'rg' '^    ' | 'cut' -c5- | 'sort' -u | 'rg' -N --no-column '^[^\W](.+)' && cd "$current_dir"
}

function tags_save_to_file() {
  local default_path="$HOME/.my_tags"
  local file_path=${1:-${default_path}}
  tags_get_all_user_tags > "$file_path"
  la "$file_path"
}

function tags_show() {
  if [ ! -f $TAGS ]; then
    tags_save_to_file
  fi

  cat "$TAGS" | fzf
}

function tags_get_total_count() {
  cat "$TAGS" | wc -l
}

function tags_add_to_file() {
  local tags_selection="$(tags_show | fzf --multi)"
}

alias tagshow=tags_show
alias tagcount=tags_get_total_count
alias tagsave=tags_save_to_file
