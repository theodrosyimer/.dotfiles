function init_package_json() {
  local repo_name="${1:-"${PWD:t:l}"}"
	(pnpm init || npm init ) 2>/dev/null && npm pkg set \
  name=$repo_name \
  type='module' \
  homepage="https://github.com/theodrosyimer/$repo_name#README" \
  bug="https://github.com/theodrosyimer/$repo_name/issues" \
  repository.type="git" \
  repository.url="git+https://github.com/theodrosyimer/$repo_name.git"
}
