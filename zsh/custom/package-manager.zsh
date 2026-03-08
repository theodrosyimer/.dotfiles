alias pjinit=init_package_json

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
