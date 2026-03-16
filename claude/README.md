# Claude Code skills and plugins

Local Plugin Sync Workflow (`ty` marketplace)

1. Edit plugin source in `~/.dotfiles/claude/plugins/<name>/`
2. Update marketplace.json — add/rename entry in `~/.dotfiles/claude/.claude-plugin/marketplace.json`
3. Update plugin.json — ensure name matches marketplace.json entry in `.claude-plugin/plugin.json`
4. Enable in settings.json — add "`<name>@ty": true` to `enabledPlugins` in `~/.dotfiles/claude/settings.json`
5. Clear cache — `rm -rf ~/.claude/plugins/cache/ty/<name>`
6. Reload — `/reload-plugins`

> [!IMPORTANT]
> Cache must be cleared after ANY change to a local plugin — Claude Code serves from cache, not source.
