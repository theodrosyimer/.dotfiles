#!/usr/bin/env bash
# Validates that the Bash tool only runs allowed git commands.
# Called as a PreToolUse hook for the conventional-commit skill.
# Allowed: git add, git commit, git status, git diff
# Blocked: git push, git reset, git stash, git rebase, etc.
# Exits 0 to allow, non-zero to block.

set -euo pipefail

command=$(jq -r '.tool_input.command // empty' < /dev/stdin)

if [ -z "$command" ]; then
  exit 0
fi

if echo "$command" | rg -q '^git (add|commit|status|diff)\b'; then
  exit 0
fi

echo "BLOCKED: Only 'git add', 'git commit', 'git status', and 'git diff' are allowed. Got: '$command'" >&2
exit 2
