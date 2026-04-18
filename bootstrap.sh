#!/usr/bin/env bash
#
# bootstrap.sh — automated new-Mac setup, described in README.md.
#
# HOW TO GET THIS FILE ONTO A FRESH MAC
#   curl -fsSL https://raw.githubusercontent.com/theodrosyimer/dotfiles/main/bootstrap.sh -o /tmp/bootstrap.sh
#   bash /tmp/bootstrap.sh
#
# IDEMPOTENT
#   Re-run any time. Each step detects whether it's already done and
#   skips. Safe after partial failures.
#
# INTERACTIVE GATES (cannot be automated, script pauses and asks)
#   • §1  1Password desktop + sign-in + enable SSH agent / CLI integration
#   • §2  Accept Xcode Command Line Tools license dialog
#   • §5  gh auth login (browser OAuth)
#   • §10 op signin (biometric or master password)

set -euo pipefail

readonly DOTFILES_REPO="theodrosyimer/dotfiles"
readonly DOTFILES_DIR="$HOME/.dotfiles"
readonly OP_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# ── helpers ──
pause()   { echo; printf '⏸  %s\n   press Enter when done… ' "$1"; read -r; }
have()    { command -v "$1" &>/dev/null; }
step()    { printf '\n── %s ──\n' "$1"; }
ok()      { printf '   ✓ %s\n' "$1"; }

# ── §1. 1Password desktop (manual install + sign-in) ──
step "1Password desktop + SSH agent"
if [[ -d /Applications/1Password.app ]]; then
  ok "1Password.app present"
else
  pause "Install 1Password desktop (App Store or downloads.1password.com). Sign in."
fi
if [[ -S "$OP_AGENT_SOCK" ]]; then
  ok "SSH agent socket live"
else
  pause "Enable Settings → Developer → 'Use the SSH agent' AND 'Integrate with 1Password CLI'"
fi

# ── §2. Xcode Command Line Tools ──
step "Xcode Command Line Tools"
if have git; then
  ok "git available"
else
  xcode-select --install 2>/dev/null || true
  pause "Accept Xcode CLT install dialog, wait until finished"
fi

# ── §3. Homebrew ──
step "Homebrew"
if have brew; then
  ok "brew installed"
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Put brew on PATH for this script (arch-aware)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── §4. gh CLI (just enough to clone) ──
step "gh CLI"
have gh || brew install gh
ok "gh available"

# ── §5. gh auth (browser OAuth) ──
step "gh auth"
if gh auth status &>/dev/null; then
  ok "gh already authenticated"
else
  gh auth login
fi

# ── §6. Clone dotfiles over HTTPS ──
step "clone dotfiles"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  ok "$DOTFILES_DIR already cloned"
else
  gh repo clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# ── §7. bootstrap/symlink.sh — symlink everything non-claude ──
step "bootstrap/symlink.sh — symlink tracked dotfiles"
"$DOTFILES_DIR/bootstrap/symlink.sh"
# Load env vars into current script shell so §8's `brew bundle --global`
# sees $HOMEBREW_BUNDLE_FILE_GLOBAL. Errors (zsh-only syntax) are tolerated.
# shellcheck disable=SC1091
source "$HOME/.zshenv" 2>/dev/null || true

# ── §7b. bootstrap/omz.sh — oh-my-zsh + external custom plugins ──
# Must run BEFORE anything that launches an interactive zsh (§9 ccsync),
# because ~/.zshrc now sources $ZSH/oh-my-zsh.sh.
step "bootstrap/omz.sh — oh-my-zsh + custom plugins"
"$DOTFILES_DIR/bootstrap/omz.sh"

# ── §8. Brewfile ──
step "brew bundle --global"
brew bundle --global

# ── §9. ccsync — depth-2 per-item symlinks for claude/ ──
step "ccsync — sync ~/.claude"
zsh -ic 'ccsync'

# ── §10. op signin ──
step "op signin"
if op whoami &>/dev/null; then
  ok "op already authenticated"
else
  eval "$(op signin)"
fi

# ── §11. bootstrap/ssh.sh — materialise ~/.ssh from 1Password ──
step "bootstrap/ssh.sh — materialise ~/.ssh"
"$DOTFILES_DIR/bootstrap/ssh.sh"

# ── §11b. bootstrap/secrets.sh — materialise per-user secret files ──
step "bootstrap/secrets.sh — materialise ~/.npmrc and any other secrets"
"$DOTFILES_DIR/bootstrap/secrets.sh"

# ── §12. Switch dotfiles remote from HTTPS to SSH ──
step "flip dotfiles remote to SSH"
current_url=$(git -C "$DOTFILES_DIR" remote get-url origin)
if [[ "$current_url" == git@* ]]; then
  ok "remote already on SSH ($current_url)"
else
  git -C "$DOTFILES_DIR" remote set-url origin "git@github.com:${DOTFILES_REPO}.git"
  git -C "$DOTFILES_DIR" fetch
  ok "remote → SSH, fetch OK"
fi

echo
echo "╔════════════════════════════════════════════╗"
echo "║   ✓ bootstrap complete                     ║"
echo "║   open a new shell for full env to load    ║"
echo "╚════════════════════════════════════════════╝"
