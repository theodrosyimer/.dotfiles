#!/usr/bin/env bash
#
# bootstrap/claude.sh — clone (or update) the private Claude Code config repo.
#
# Why this exists: global agent configuration — skills, hooks, rules, the `ty`
# plugin marketplace, CLAUDE.md, settings.json — lives in its own PRIVATE repo,
# not in this public dotfiles repo. `ccsync` (zsh/custom/agents.zsh) symlinks
# items out of it into ~/.claude/, ~/.agents/ and ~/.codex/, so this must run
# BEFORE the ccsync step in bootstrap.sh or ccsync has no source to link from.
#
# It is a separate repo rather than a submodule on purpose: a submodule pointer
# in the public dotfiles repo would expose the private repo's URL and break
# `git clone --recurse-submodules` for anyone else.
#
# Idempotent — clones only when the target is missing, otherwise fast-forwards.
# A dirty or diverged working tree is reported and left alone, never reset.
#
# Requires: gh, authenticated (bootstrap.sh runs `gh auth login` beforehand).
#
# Usage:
#   ~/.dotfiles/bootstrap/claude.sh

set -euo pipefail

readonly CLAUDE_REPO="theodrosyimer/claude-code"
readonly CLAUDE_SRC="${CLAUDE_SRC:-$HOME/dev/projects/personal/claude-code}"

command -v gh >/dev/null || { echo "gh not found — run bootstrap.sh, which installs it"; exit 1; }

if [[ -d "$CLAUDE_SRC/.git" ]]; then
  echo "  ✓ $CLAUDE_SRC already cloned"
  if [[ -n "$(git -C "$CLAUDE_SRC" status --porcelain)" ]]; then
    echo "  ! working tree is dirty — skipping pull, resolve by hand"
  elif git -C "$CLAUDE_SRC" pull --ff-only --quiet; then
    echo "  ✓ fast-forwarded to origin"
  else
    echo "  ! pull is not a fast-forward — resolve by hand"
  fi
else
  mkdir -p "$(dirname "$CLAUDE_SRC")"
  echo "→ cloning $CLAUDE_REPO"
  gh repo clone "$CLAUDE_REPO" "$CLAUDE_SRC"
fi

echo "✓ claude config repo ready at $CLAUDE_SRC"
