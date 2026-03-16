function sksym() {
  local errors=()

	if ln -s ~/.dotfiles/claude/skills/* ~/.claude/skills 2>/dev/null; then
    echo "Skills symlinked successfully."
  else
    errors+=("~/.claude/skills")
  fi
	if ln -s ~/.dotfiles/claude/skills/* ~/.agents/skills 2>/dev/null; then
    echo "Skills symlinked successfully."
  else
    errors+=("~/.agents/skills")
  fi

  echo "Failed to create symlinks in ${errors[@]}."
  echo "Please check if the source and target directories exist."
}

function skadd() {
	npx skills add https://github.com/theodrosyimer/dotfiles/skills --skill "${1}"
}
