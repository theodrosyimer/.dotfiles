alias pinit=init_package_json

function copyReadMeTo() {
  cp $CODE_TEMPLATES/dev-config/docs/app/README.md "${1:-.}"
}

function init_package_json() {
  if [[ -f "package.json" ]]; then
      printf '\n%s\n' "File already exists at $_cyan$PWD/package.json$_reset" && exit 1
  fi

  local repo_name="${1:-"${PWD:t:l}"}"

  (pnpm init || npm init ) >/dev/null && \
  cat package.json | jq \
  ".name = \"$repo_name\" | \
  .type = \"module\" | \
  .homepage = \"https://github.com/theodrosyimer/$repo_name#README\" | \
  .bug = \"https://github.com/theodrosyimer/$repo_name/issues\" | \
  .repository.type = \"git\" | \
  .repository.url = \"git+https://github.com/theodrosyimer/$repo_name.git\" | \
  .files = [\"dist\"] | \
  .packageManager = \"pnpm@$(pnpm -v)\"" > package.json

  cat package.json
}
