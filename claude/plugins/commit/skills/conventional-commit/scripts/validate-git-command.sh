#!/usr/bin/env bash
# Validates that the Bash tool is only used to run `git diff --staged`.
# Called as a PreToolUse hook for the commit-message-generator skill.
# Exits 0 to allow, non-zero to block.

set -euo pipefail

TOOL_INPUT="$*"

# Extract the command value from the JSON tool input.
# Handles both quoted and unquoted forms.
COMMAND=$(echo "$TOOL_INPUT" | grep -oP '"command"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$TOOL_INPUT")

# Trim whitespace
COMMAND=$(echo "$COMMAND" | xargs)

if [ "$COMMAND" = "git diff --staged" ]; then
  exit 0
fi

echo "BLOCKED: Only 'git diff --staged' is allowed. Got: '$COMMAND'" >&2
echo "The commit-message-generator skill is restricted to reading staged diffs only." >&2
exit 1
