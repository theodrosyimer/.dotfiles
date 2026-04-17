#!/usr/bin/env bash
# Fires on SessionStart — injects a reminder to actively cross-reference
# global CLAUDE.md, project CLAUDE.md, and project rules during the session.

set -euo pipefail

project_dir=$(jq -r '.cwd // "."' < /dev/stdin)

context_files=()

if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
  context_files+=("$HOME/.claude/CLAUDE.md (global preferences)")
fi

if [[ -f "$project_dir/CLAUDE.md" ]]; then
  context_files+=("CLAUDE.md (project-level)")
fi

rules_dir="$project_dir/.claude/rules"
if [[ -d "$rules_dir" ]]; then
  rule_count=$(fd -e md --type f . "$rules_dir" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$rule_count" -gt 0 ]]; then
    context_files+=(".claude/rules/ ($rule_count rule files)")
  fi
fi

if [[ ${#context_files[@]} -eq 0 ]]; then
  exit 0
fi

reminder="ACTIVE CONVENTION CHECK — Before generating any artifact (code, docs, configs, handoffs, setup), cross-reference your conventions from:"
for f in "${context_files[@]}"; do
  reminder+=$'\n'"- $f"
done
reminder+=$'\n'"Apply these to everything you produce. Do NOT write generic boilerplate when specific conventions exist in these files."

jq -n --arg ctx "$reminder" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
