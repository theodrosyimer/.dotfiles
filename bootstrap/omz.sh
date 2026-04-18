#!/usr/bin/env bash
#
# bootstrap/omz.sh — install oh-my-zsh and its external custom plugins.
#
# Why this exists: the dotfiles ~/.zshrc references oh-my-zsh (loads
# $ZSH/oh-my-zsh.sh, uses plugins from $ZSH_CUSTOM). Without omz +
# plugins on disk, the shell errors out on every new session.
#
# Idempotent — runs `git clone` only when the target directory is
# missing or not a git repo. Safe to re-run.
#
# NOT HANDLED
#   On your current Mac these exist under ~/.dotfiles/zsh/custom/plugins/
#   but they're NOT standalone git repos AND NOT tracked in dotfiles:
#     • bid              (your own code — not listed in ~/.zshrc plugins=)
#     • git              (your own override — IS listed in ~/.zshrc;
#                         omz will fall back to its built-in `git` plugin
#                         on a fresh Mac until you extract or track it)
#     • package-manager  (your own code — not listed in ~/.zshrc plugins=)
#   Options to fix: extract each into a separate repo and add a row
#   below, or `git add -f` their contents so bootstrap/symlink.sh picks
#   them up.
#
# Usage:
#   ~/.dotfiles/bootstrap/omz.sh

set -euo pipefail

command -v git >/dev/null || { echo "git not found — install Xcode Command Line Tools first"; exit 1; }

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.dotfiles/zsh/custom}"

clone_if_missing() {
  local name="$1" url="$2" target="$3"
  if [[ -d "$target/.git" ]]; then
    echo "  ✓ $name (already present)"
  else
    echo "→ cloning $name"
    git clone --depth=1 "$url" "$target"
  fi
}

# oh-my-zsh itself
clone_if_missing "oh-my-zsh" "https://github.com/ohmyzsh/ohmyzsh.git" "$ZSH_DIR"

# External plugins listed in ~/.zshrc plugins=(…). Format:
#   name | upstream URL (no spaces around '|')
# Each name must match an entry in your ~/.zshrc plugins array. omz
# built-ins (brew, git, macos) ship with oh-my-zsh itself — no clone
# needed. zsh-vi-mode is NOT here because your ~/.zshrc sources it
# from Homebrew ($(brew --prefix)/opt/zsh-vi-mode/…), not as an omz
# custom plugin.
mkdir -p "$ZSH_CUSTOM_DIR/plugins"
while IFS='|' read -r name url; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  clone_if_missing "$name" "$url" "$ZSH_CUSTOM_DIR/plugins/$name"
done <<'EOF'
fzf-tab|https://github.com/Aloxaf/fzf-tab
you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use.git
zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions
zsh-completions|https://github.com/zsh-users/zsh-completions
zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git
EOF

echo "✓ oh-my-zsh + external plugins ready"
