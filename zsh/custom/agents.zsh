# agents.zsh — Claude Code agent utilities
#
# Manages symlinks for CLAUDE.md, skills, hooks, and rules between dotfiles
# and Claude/agent config directories. Includes skill installation
# and plugin cache management.
#
# Dependencies: npx (for skadd)
# Provided by oh-my-zsh auto-sourcing $ZSH_CUSTOM/*.zsh

function _cc_sync_link() {
  local src="$1" dest="$2" force="$3"

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      ((skipped++))
      return 0
    elif [[ "$force" == true ]]; then
      rm "$dest" && ln -s "$src" "$dest"
      ((++updated))
      echo "  ��� ${dest:t} (retargeted)"
    else
      conflicts+=("$dest → $(readlink "$dest") (expected $src)")
    fi
  elif [[ -e "$dest" ]]; then
    conflicts+=("$dest (not a symlink, won't overwrite)")
  else
    ln -s "$src" "$dest" && ((++created)) && echo "  + ${dest:t}"
  fi
}

function ccsync() {
  local force=false
  [[ "$1" == "--force" || "$1" == "-f" ]] && force=true

  local created=0 skipped=0 updated=0
  local conflicts=()

  # --- 1. CLAUDE.md ---
  mkdir -p ~/.claude
  _cc_sync_link ~/.dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md $force

  # --- 2. Directory pairs: skills, hooks, rules ---
  local pairs=(
    ~/.dotfiles/claude/skills ~/.claude/skills
    ~/.dotfiles/claude/hooks  ~/.claude/hooks
    ~/.dotfiles/claude/rules  ~/.claude/rules
  )

  for ((i=1; i<=${#pairs[@]}; i+=2)); do
    local src_dir="${pairs[$i]}"
    local dst_dir="${pairs[$((i+1))]}"

    echo "\n${src_dir:t}/:"

    if [[ ! -d "$src_dir" ]]; then
      echo "  (source missing, skipped)"
      continue
    fi

    mkdir -p "$dst_dir"

    for item in "$src_dir"/*; do
      [[ -e "$item" ]] || continue
      _cc_sync_link "$item" "$dst_dir/${item:t}" $force
    done
  done

  # --- summary ---
  echo "\n── summary ──"
  echo "created: $created  unchanged: $skipped  updated: $updated"
  if (( ${#conflicts[@]} )); then
    echo "conflicts (${#conflicts[@]}):"
    printf '  - %s\n' "${conflicts[@]}"
    echo "run 'ccsync --force' to retarget wrong symlinks"
  fi
}

function skadd() {
	npx skills add https://github.com/theodrosyimer/dotfiles/skills --skill "${1}"
}

function _cc_rm_plugin_cache() {
  rm -rf ~/.claude/plugins/cache/"${1:-ty}"/*
}

function ccpsync() {
  local src_dir=~/.dotfiles/claude/plugins
  local cleared=()

  if [[ ! -d "$src_dir" ]]; then
    echo "No plugins source at $src_dir"
    return 1
  fi

  if (( $# )); then
    # sync named plugins only
    for name in "$@"; do
      if [[ -d "$src_dir/$name" ]]; then
        _cc_rm_plugin_cache "ty/$name"
        cleared+=("$name")
      else
        echo "  ✗ $name (not found in $src_dir)"
      fi
    done
  else
    # sync all plugins
    for dir in "$src_dir"/*(N/); do
      _cc_rm_plugin_cache "ty/${dir:t}"
      cleared+=("${dir:t}")
    done
  fi

  if (( ${#cleared[@]} )); then
    echo "cache cleared: ${(j:, :)cleared}"
    echo "run /reload-plugins in Claude Code"
  else
    echo "no plugins to sync"
  fi
}
