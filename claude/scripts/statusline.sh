#!/bin/bash
# Claude Code status line: Starship prompt (line 1) + ccusage burn rate (line 2)
input=$(cat)

# Line 1: Starship prompt using session cwd for accurate git/directory context
# STARSHIP_SHELL="" forces plain ANSI escapes instead of zsh %{...%} wrappers
# head -1 strips the character/prompt line (❯) which isn't useful in a status bar
cwd=$(echo "$input" | jq -r '.cwd // empty')
STARSHIP_SHELL="" STARSHIP_CONFIG="/Users/ty/.dotfiles/starship/starship.toml" \
  starship prompt --path "${cwd:-$PWD}" | head -1

# Line 2: ccusage burn rate
echo "$input" | bun x ccusage statusline --visual-burn-rate emoji 2>/dev/null
