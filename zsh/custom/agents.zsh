# ── plugins ──────────────────────────────────────────────────────────────────

function _cc_rm_plugin_cache() {
  rm -rf ~/.claude/plugins/cache/"${1:-ty}"/*
}

function ccpsync() {
  local src_dir="$CLAUDE_SRC/plugins"
  local cleared=()

  if [[ ! -d "$src_dir" ]]; then
    echo "No plugins source at $src_dir"
    return 1
  fi

  if (( $# )); then
    for name in "$@"; do
      if [[ -d "$src_dir/$name" ]]; then
        _cc_rm_plugin_cache "ty/$name"
        cleared+=("$name")
      else
        echo "  ✗ $name (not found in $src_dir)"
      fi
    done
  else
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

function skadd() {
	npx skills add https://github.com/theodrosyimer/claude-code/skills --skill "${1}"
}
