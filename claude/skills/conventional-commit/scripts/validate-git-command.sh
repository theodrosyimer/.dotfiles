#!/usr/bin/env bash
# Validates that the Bash tool only runs allowed git commands.
# Called as a PreToolUse hook for the conventional-commit skill.
# Allowed: git add, git commit, git status, git diff
# Blocked: git push, git reset, git stash, git rebase, etc.
# Exits 0 to allow, non-zero to block.

set -euo pipefail

TOOL_INPUT="$*"

# Extract the command value from the JSON tool input.
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
if [ -z "$COMMAND" ]; then
  COMMAND="$TOOL_INPUT"
fi

# Allow: git add, git commit, git status, git diff
if echo "$COMMAND" | rg -q '^git (add|commit|status|diff)\b'; then
  exit 0
fi

echo "BLOCKED: Only 'git add', 'git commit', 'git status', and 'git diff' are allowed. Got: '$COMMAND'" >&2
echo "The conventional-commit skill is restricted to staging, committing, and reading diffs." >&2
exit 1
