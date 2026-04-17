#!/usr/bin/env bash
# Blocks /bin/rm and /bin/rmdir — use rm, an alias for trash (macos) instead.
# Called as a PreToolUse hook from settings.json.

set -euo pipefail

command=$(jq -r '.tool_input.command // empty' < /dev/stdin)

if echo "$command" | rg -q '/bin/rm(dir)?\b'; then
  echo 'Use rm/rmdir (aliased to trash) instead of /bin/rm or /bin/rmdir' >&2
  exit 2
fi
