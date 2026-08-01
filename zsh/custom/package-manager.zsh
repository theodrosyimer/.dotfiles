alias pjinit=init_package_json

# The following are only needed for installing private packages — publishing is
# tokenless (release-it + npm provenance).
# The token is injected per-invocation and is deliberately absent from ~/.npmrc:
# a `${NPM_TOKEN}` placeholder there makes pnpm warn on *every* call, since the
# variable is only defined inside these wrappers.
# `/usr/bin/env` (not `env`) because `env` is aliased in aliases.zsh, which is
# sourced before this file, so a bare `env` would be alias-expanded here.
# `npq-hero` is spelled out because the pnpm/npm aliases can't expand as an
# argument of `env` — this keeps the npq audit in the chain as before.

# Credential lives at op://Dev Perso/npm/token (1Password, "Dev Perso" vault).
# A 401 from any of the wrappers below means that token is expired or revoked —
# it is NOT a plumbing problem. Mint a new one at npmjs.com → Access Tokens
# (Granular; read access to your private packages is enough — publishing does
# not use this token) and update the `token` field of the `npm` item.
# Isolate token from plumbing with:
#   curl -s -o /dev/null -w '%{http_code}\n' \
#     -H "Authorization: Bearer $(op read 'op://Dev Perso/npm/token')" \
#     https://registry.npmjs.org/-/whoami
function _npm_token() {
  op read "op://Dev Perso/npm/token"
}

# $1 — name of the wrapper that failed
function _npm_token_error() {
  print -u2 "$1: aborted — could not read the npm token from 1Password (op://Dev Perso/npm/token)"
  return 1
}

# `pnpm_config__auth` is pnpm's explicitly trusted env location (v11.10.0+).
# The `pnpm_config_//registry…:_authToken` form still works, but only via pnpm's
# legacy raw-config path: the typed reader (config/reader/lib/env.js) accepts a
# `pnpm_config_*` key only when its suffix is snake_case and matches a known
# schema, and that legacy path is what the v11 .npmrc security work keeps
# narrowing.
function pnpms() {
  local token auth
  token=$(_npm_token) || { _npm_token_error "pnpms"; return 1 }
  auth=$(jq -nc --arg token "$token" \
    '{"https://registry.npmjs.org/": {"@": {authToken: $token}}}')
  /usr/bin/env "pnpm_config__auth=$auth" NPQ_PKG_MGR=pnpm npq-hero "$@"
}

function npms() {
  local token
  token=$(_npm_token) || { _npm_token_error "npms"; return 1 }
  /usr/bin/env "npm_config_//registry.npmjs.org/:_authToken=$token" npq-hero "$@"
}

# bun has no NPM_CONFIG_*/BUN_CONFIG_* override, so it reads the token from a
# dedicated bunfig that expands $NPM_TOKEN.
function buns() {
  local token
  token=$(_npm_token) || { _npm_token_error "buns"; return 1 }
  NPM_TOKEN=$token bun --config="$DOTFILES/bun/auth.bunfig.toml" "$@"
}

function copyReadMeTo() {
  cp $CODE_TEMPLATES/dev-config/docs/app/README.md "${1:-.}"
}

function init_package_json() {
  local repo_name="${1:-"${PWD:t:l}"}"
  local pm

  vared -p "Package manager (pnpm/npm/yarn/bun): " pm
  pm="${pm:-pnpm}"

  [[ -f "package.json" ]] || ($pm init) >/dev/null

  local tmp=$(mktemp ./package.json.XXXXXX)
  # here `rm` is aliased to `trash` (safe move to trash). If you use /bin/rm, failed jq runs will permanently delete the temp file — harmless, but be aware.
  trap "[ -f '$tmp' ] && rm '$tmp'" EXIT

  jq \
    --arg name "$repo_name" \
    --arg pm "$pm" \
    --arg pm_ver "$($pm -v)" \
    '.name = $name |
     .type = "module" |
     .homepage = "https://github.com/theodrosyimer/\($name)#README" |
     .bug = "https://github.com/theodrosyimer/\($name)/issues" |
     .repository.type = "git" |
     .repository.url = "git+https://github.com/theodrosyimer/\($name).git" |
     .files = ["dist"] |
     .packageManager = "\($pm)@\($pm_ver)"' \
    package.json > "$tmp" && mv "$tmp" package.json

  cat package.json
}

