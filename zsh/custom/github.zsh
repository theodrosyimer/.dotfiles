# TODO add option to create a public repository
function gh_repo_create_from_cwd() {
  local repo_visibility="${1:-private}"
  'gh' repo create --source="$(pwd)" --remote=upstream "--$repo_visibility" --description="$2" && 'git' push -u origin main
}

alias ghls="gh repo list"
alias ghlspr="gh repo list --limit 100 --visibility=private"
alias ghlspu="gh repo list --limit 100 --visibility=public"
alias ghrm="gh repo delete"
alias ghcreate=gh_repo_create_from_cwd
