# TODO add option to create a public repository
function gh_repo_create_from_cwd() {
  local repo_visibility="${1:-private}"
  'gh' repo create --source="$(pwd)" --remote=upstream "--$repo_visibility" --description="$2" && 'git' push -u origin main
}

alias ghrls="gh repo list"
alias ghrlpr="gh repo list --limit 100 --visibility=private"
alias ghrlpu="gh repo list --limit 100 --visibility=public"
alias ghrd="gh repo delete"
alias ghcreate=gh_repo_create_from_cwd
