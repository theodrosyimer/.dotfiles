#!/usr/bin/env bash
#
# bootstrap/ssh.sh — set up ~/.ssh on a new machine from 1Password.
#
# WHAT THIS SCRIPT DOES
#   • Downloads ~/.ssh/config from 1Password (stored as a Document).
#   • Writes the *.pub files that the config references via IdentityFile.
#   • Fixes permissions on ~/.ssh, config, and *.pub.
#
#   Private keys are never written to disk. They stay inside 1Password
#   and are used at connection time by the 1Password SSH agent.
#
# PRE-REQUISITES (every machine that runs this script)
#   1. 1Password desktop installed, signed in, SSH agent enabled
#      (Settings → Developer → "Use the SSH agent").
#   2. 1Password CLI:  brew install 1password-cli
#   3. Signed in to the CLI:  eval "$(op signin)"
#      (or biometric unlock configured for `op`).
#
# WHAT 1PASSWORD MUST CONTAIN
#   • SSH Key items in the vaults listed in VAULTS below. Each item's
#     title is converted to the on-disk *.pub filename via this rule:
#         lowercase the title, replace " - " with "_", append ".pub"
#     Examples:
#         "Perso - Github"                  →  perso_github.pub
#         "Perso - VPS - Hostinger"         →  perso_vps_hostinger.pub
#         "PRO - COMPANY - Gitlab - REPONAME" →  pro_company_gitlab_reponame.pub
#     Rename the 1Password item to control the filename — no script edit
#     needed when you add, remove, or rename keys.
#   • A Document titled "ssh config" in the "Dev Perso" vault, whose
#     content is the full ~/.ssh/config file.
#
# HOW TO PUT THE SSH CONFIG INTO 1PASSWORD
#   Not done by this script — do it once, from a machine that already
#   has a working ~/.ssh/config:
#
#     # first time:
#     op document create ~/.ssh/config \
#         --title "ssh config" --vault "Dev Perso"
#
#     # after editing ~/.ssh/config locally, push the new version:
#     op document edit "ssh config" --vault "Dev Perso" ~/.ssh/config
#
# USAGE
#   ~/.dotfiles/bootstrap/ssh.sh

VAULTS=("Dev Perso" "Pro")

set -euo pipefail

command -v op >/dev/null || { echo "op CLI not found — brew install 1password-cli"; exit 1; }
command -v jq >/dev/null || { echo "jq not found — brew install jq"; exit 1; }
op whoami >/dev/null 2>&1 || { echo "not signed in to 1Password — run: eval \"\$(op signin)\""; exit 1; }

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "→ fetching ~/.ssh/config from 1Password"
op document get "ssh config" --vault "Dev Perso" --out-file ~/.ssh/config --force
chmod 600 ~/.ssh/config

echo "→ fetching public keys"
for vault in "${VAULTS[@]}"; do
  while IFS= read -r title; do
    file="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed 's/ - /_/g').pub"
    echo "  • ${file}  ←  [${vault}] ${title}"
    op read "op://${vault}/${title}/public key" > ~/.ssh/"$file"
    chmod 644 ~/.ssh/"$file"
  done < <(op item list --vault "$vault" --categories "SSH Key" --format json | jq -r '.[].title' | sort)
done

echo "✓ done. verify with:  ssh -v vps 'echo ok'"
