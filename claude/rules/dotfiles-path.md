All global Claude Code configuration (skills, rules, hooks, plugins) lives in `~/.dotfiles/claude/`.
Individual items are symlinked into `~/.claude/` (e.g., `~/.claude/skills/foo` → `~/.dotfiles/claude/skills/foo`).

When placing global files, always create in `~/.dotfiles/claude/{type}/` and symlink to `~/.claude/{type}/`.
Never create global config directly in `~/.claude/`.
