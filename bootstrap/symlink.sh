#!/usr/bin/env bash
#
# bootstrap/symlink.sh — symlink tracked dotfiles into their canonical locations.
#
# SOURCE OF TRUTH
#   `git ls-files` in each package. Only git-tracked files are linked;
#   untracked and gitignored files are skipped automatically — no
#   separate `.stow-local-ignore` or equivalent needed.
#
# LINK GRANULARITY
#   Top-level entries of each package. A tracked directory becomes one
#   directory symlink (e.g. ~/.claude/skills → ~/dev/projects/personal/claude-code/skills).
#   A tracked file becomes a file symlink (e.g. ~/.zshenv).
#
# USAGE
#   ~/.dotfiles/bootstrap/symlink.sh              apply
#   DRY_RUN=1 ~/.dotfiles/bootstrap/symlink.sh    preview, no writes
#
# IDEMPOTENT
#   `ln -sfn` overwrites existing symlinks in place. Re-run after
#   adding / removing tracked files to reconcile.
#
# CONFLICTS
#   If a target path already exists as a real file or directory (not a
#   symlink) `ln -sfn` will refuse to overwrite it and error out. Move
#   or delete the real path, then re-run.
#
# NOT HANDLED HERE
#   The private claude-code config repo is managed by `agsync` (aliased in
#   zsh/custom/aliases.zsh), not by this script. It links per item inside
#   skills/, hooks/, rules/ — a different granularity — and then generates
#   the artifacts Codex needs in its own format.

set -euo pipefail

cd "$(dirname "$0")/.."   # dotfiles root (this script lives in bootstrap/)
SRC="$PWD"
DRY="${DRY_RUN:-}"

# Top-level entries to skip per package.
# Reason: tracked in git but not meant to be symlinked into the target.
# A function, not an associative array: bootstrap.sh runs this script (§7) before
# `brew bundle` installs Homebrew's bash (§8), so it must work on macOS's bash 3.2,
# which has no `declare -A`.
skip_entries() {
  case $1 in
    zsh) echo "custom" ;;           # loaded via $ZSH_CUSTOM, not via ~/custom symlink
    git) echo "templates" ;;        # referenced via init.templateDir, not via ~/templates
    node-shims) echo "fnm-exec" ;;  # the script the name links point at, not a program of its own
  esac
}

link_pkg() {
  local pkg="$1" target="$2"
  [[ -d "$SRC/$pkg" ]] || { printf '  ~ skip %-14s (missing dir)\n' "$pkg"; return; }

  local entries
  entries=$(git -C "$SRC/$pkg" ls-files 2>/dev/null | cut -d/ -f1 | sort -u)
  if [[ -z "$entries" ]]; then
    printf '  ~ skip %-14s (no tracked files)\n' "$pkg"
    return
  fi

  local skip
  skip=$(skip_entries "$pkg")
  printf '→ %-14s → %s\n' "$pkg" "$target"
  [[ -n "$DRY" ]] || mkdir -p "$target"

  while IFS= read -r entry; do
    if [[ -n "$skip" ]] && [[ " $skip " == *" $entry "* ]]; then
      printf '    skipped: %s\n' "$entry"
      continue
    fi
    local dest="$target/$entry"
    local src="$SRC/$pkg/$entry"
    if [[ -n "$DRY" ]]; then
      printf '    would link: %s → %s\n' "$dest" "$src"
    else
      ln -sfn "$src" "$dest"
      printf '    linked: %s\n' "$dest"
    fi
  done <<< "$entries"
}

# $HOME
link_pkg zsh          "$HOME"
link_pkg git          "$HOME"
link_pkg tmux         "$HOME"
link_pkg nano         "$HOME"
link_pkg npm          "$HOME"
link_pkg ripgrep      "$HOME"
link_pkg markdownlint "$HOME"
link_pkg ncu          "$HOME"
link_pkg yaml         "$HOME"

# ~/.local/bin is on PATH for every shell and for apps that start programs without a
# shell (MCP servers), so the Node shims reach all of them. See node-shims/fnm-exec.
link_pkg node-shims   "$HOME/.local/bin"

# ~/.config/<tool>
link_pkg nvim         "$HOME/.config/nvim"
link_pkg ghostty      "$HOME/.config/ghostty"
link_pkg karabiner    "$HOME/.config/karabiner"
link_pkg skhd         "$HOME/.config/skhd"
link_pkg yabai        "$HOME/.config/yabai"
link_pkg aerospace    "$HOME/.config/aerospace"
link_pkg fd           "$HOME/.config/fd"
link_pkg yt-dlp       "$HOME/.config/yt-dlp"

# macOS-specific
link_pkg keybindings  "$HOME/Library/KeyBindings"
# rtk reads this path and ONLY this path — no --config flag, no RTK_CONFIG env
# var, and XDG_CONFIG_HOME is ignored (all three measured 2026-08-12), so a
# symlink is the only way to track it.
link_pkg rtk          "$HOME/Library/Application Support/rtk"

echo "✓ bootstrap/symlink.sh done — now run 'agsync' to sync ~/.claude, ~/.agents and ~/.codex"
