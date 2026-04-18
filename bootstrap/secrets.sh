#!/usr/bin/env bash
#
# bootstrap/secrets.sh — materialise per-user secret files from 1Password.
#
# Each entry in the table below is a document stored in 1Password whose
# content is the full body of the target file (e.g. ~/.npmrc with its
# auth tokens, ~/.aws/credentials with its access keys, …). On a fresh
# machine this script fetches each one and writes it with appropriate
# permissions.
#
# Prerequisites on a fresh machine:
#   1. 1Password desktop installed, signed in
#   2. 1Password CLI: brew install 1password-cli
#   3. Signed in to the CLI: eval "$(op signin)"
#      (or biometric unlock configured for `op`)
#
# What 1Password must contain:
#   A Document per row in the SECRETS table below, with the given title
#   in the given vault. The document's content must be the exact file
#   body (multi-line, secrets included).
#
# How to put a secret file INTO 1Password (one-time, per file):
#   op document create ~/.npmrc --title "npmrc" --vault "Dev Perso"
#
#   # update later after local edits:
#   op document edit "npmrc" --vault "Dev Perso" ~/.npmrc
#
# Usage:
#   ~/.dotfiles/bootstrap/secrets.sh

set -euo pipefail

command -v op >/dev/null || { echo "op CLI not found — brew install 1password-cli"; exit 1; }
op whoami >/dev/null 2>&1 || { echo "not signed in to 1Password — run: eval \"\$(op signin)\""; exit 1; }

# format: item | vault | ~/-relative destination | chmod mode | optional ~/-relative symlink
# '#' at line start = comment. No spaces around '|'. 5th field is
# optional; when present, ~/<symlink> is created pointing to the
# fetched file (so e.g. npm can find ~/.npmrc without
# bootstrap/symlink.sh needing to track the gitignored file).
while IFS='|' read -r item vault rel_dest mode rel_symlink; do
  [[ -z "$item" || "$item" == \#* ]] && continue
  dest="$HOME/$rel_dest"

  mkdir -p "$(dirname "$dest")"
  echo "→ ${dest/#$HOME/~}  ←  [${vault}] ${item}"

  op document get "$item" --vault "$vault" --out-file "$dest" --force
  chmod "$mode" "$dest"

  if [[ -n "$rel_symlink" ]]; then
    symlink="$HOME/$rel_symlink"
    ln -sfn "$dest" "$symlink"
    echo "  ↳ ${symlink/#$HOME/~} → ${dest/#$HOME/~}"
  fi
done <<'EOF'
npmrc|Dev Perso|.dotfiles/npm/.npmrc|600|.npmrc
EOF

echo "✓ secrets written"
