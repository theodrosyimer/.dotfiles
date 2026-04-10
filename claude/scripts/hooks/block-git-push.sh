#!/usr/bin/env bash
# Blocks git push globally — user must push manually.
# Called as a PreToolUse hook from settings.json.

set -euo pipefail

command=$(jq -r '.tool_input.command // empty' < /dev/stdin)

if echo "$command" | rg -q '^git\s+push\b'; then
  echo 'BLOCKED: git push is not allowed. Ask the user to push manually.' >&2
  exit 2
fi
