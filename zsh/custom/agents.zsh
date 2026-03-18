function ccsync() {
  local errors=()

  local src=~/.dotfiles/claude/CLAUDE.md
  local dest=~/.claude/CLAUDE.md
  if [[ -L "$dest" || -e "$dest" ]]; then
    errors+=("$dest (exists)")
  elif ! ln -s "$src" "$dest" 2>/dev/null; then
    errors+=("$dest")
  else
    echo "Linked CLAUDE.md → ~/.claude"
  fi

  local pairs=(
    ~/.dotfiles/claude/skills ~/.claude/skills
    ~/.dotfiles/claude/skills ~/.agents/skills
    ~/.dotfiles/claude/hooks  ~/.claude/hooks
    ~/.dotfiles/claude/hooks  ~/.agents/hooks
  )

  for ((i=1; i<=${#pairs[@]}; i+=2)); do
    local src_dir="${pairs[$i]}"
    local dst_dir="${pairs[$((i+1))]}"

    [[ -d "$src_dir" ]] || { errors+=("$src_dir (missing source)"); continue; }
    mkdir -p "$dst_dir"

    for file in "$src_dir"/*; do
      [[ -e "$file" ]] || continue
      local dest="$dst_dir/${file:t}"

      if [[ -L "$dest" || -e "$dest" ]]; then
        errors+=("$dest (exists)")
      elif ! ln -s "$file" "$dest" 2>/dev/null; then
        errors+=("$dest")
      else
        echo "Linked ${file:t} → $dst_dir"
      fi
    done
  done

  if (( ${#errors[@]} )); then
    echo "\nSkipped/failed:"
    printf '  - %s\n' "${errors[@]}"
  else
    echo "All symlinks created."
  fi
}

function skadd() {
	npx skills add https://github.com/theodrosyimer/dotfiles/skills --skill "${1}"
}

function pluginsrm() {
  rm -rf ~/.claude/plugins/cache/ty/*
}
