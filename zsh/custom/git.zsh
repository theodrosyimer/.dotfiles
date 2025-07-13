# Initialize colors if not already done
autoload -U colors && colors
: ${_red=$fg[red]}
: ${_green=$fg[green]}
: ${_yellow=$fg[yellow]}
: ${_cyan=$fg[cyan]}
: ${_reset=$reset_color}

function git_add_all_commit() {
  local commit_message="${1:-Initial commit}"

  git add -A || return 1

  # Check if there are changes to commit
  if git diff --cached --quiet; then
    printf "%b\n" "$_yellow""No changes to commit$_reset"
    return 0
  fi

  # Handle first commit case
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git commit -m "$commit_message"
  else
    git commit -m "$commit_message" --allow-empty
  fi
}

function git_add_all_commit_push() {
  if git_add_all_commit "$1"; then
    git push || return 1
  fi
}

function git_clone_clean_from_front_tab_chrome() {
  local flag_help flag_path flag_name flag_https
  local dir_path="${CODE_PERSONAL:-$PWD}"
  local usage=(
    "git_clone_clean_from_front_tab_chrome [-h|--help] [-p|--path <path>] [-n|--name <name>] [--https]"
    "  -h, --help     Show this help message"
    "  -p, --path     Specify output directory (default: $dir_path)"
    "  -n, --name     Specify project name"
    "     --https     Use HTTPS instead of SSH (default: SSH)"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {p,-path}:=flag_path \
    {n,-name}:=flag_name \
    -https=flag_https || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  # Check dependencies
  is_installed tiged "tiged is required. Run: npm i -g tiged" || return 1

  local url="$(chrome_get_front_window_url)"
  [[ -z "$url" ]] && { printf "%b\n" "$_red""Failed to get URL from Chrome$_reset"; return 1 }

  local repo=${url:t2}
  local project_name="${flag_name[-1]:-${repo:t}}"
  local clone_path="${flag_path[-1]:-$dir_path}/$project_name"

  # Determine if using SSH or HTTPS (SSH by default)
  local clone_url
  if [[ -n "$flag_https" ]]; then
    clone_url="https://github.com/$repo"
  else
    clone_url="git@github.com:$repo"
  fi

  if tiged "$clone_url" "$clone_path"; then
    $EDITOR "$clone_path"
    return 0
  else
    printf "%b\n" "$_red""Failed to clone repository$_reset"
    return 1
  fi
}

function git_clone_from_front_tab_chrome() {
  local flag_help flag_path flag_name flag_https
  local dir_path="${CODE_PERSONAL:-$PWD}"
  local usage=(
    "git_clone_from_front_tab_chrome [-h|--help] [-p|--path <path>] [-n|--name <name>] [--https]"
    "  -h, --help     Show this help message"
    "  -p, --path     Specify output directory (default: $dir_path)"
    "  -n, --name     Specify project name"
    "     --https     Use HTTPS instead of SSH (default: SSH)"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {p,-path}:=flag_path \
    {n,-name}:=flag_name \
    -https=flag_https || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  # Check dependencies
  is_installed git "Git is required. Please install it first." || return 1

  local url="$(chrome_get_front_window_url)"
  [[ -z "$url" ]] && { printf "%b\n" "$_red""Failed to get URL from Chrome$_reset"; return 1 }

  local repo=${url:t2}
  local project_name="${flag_name[-1]:-${repo:t}}"
  local clone_path="${flag_path[-1]:-$dir_path}/$project_name"

  # Determine if using SSH or HTTPS (SSH by default)
  local clone_url
  if [[ -n "$flag_https" ]]; then
    clone_url="https://github.com/$repo"
  else
    clone_url="git@github.com:$repo"
  fi

  if git clone "$clone_url" "$clone_path"; then
    $EDITOR "$clone_path"
    return 0
  else
    printf "%b\n" "$_red""Failed to clone repository$_reset"
    return 1
  fi
}

function git_clone_clean_from_cb() {
  local flag_help flag_path flag_https
  local usage=(
    "git_clone_clean_from_cb [-h|--help] [-p|--path <path>] [--https]"
    "  -h, --help     Show this help message"
    "  -p, --path     Specify output directory (default: current directory)"
    "     --https     Use HTTPS instead of SSH (default: SSH)"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {p,-path}:=flag_path \
    -https=flag_https || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  is_installed tiged "tiged is required. Run: npm i -g tiged" || return 1

  local url="$(pbpaste)"
  local dir_path="${flag_path[-1]:-$PWD}"

  # Convert HTTPS URL to SSH if needed and not explicitly requested HTTPS
  if [[ -z "$flag_https" && "$url" =~ ^https://github.com ]]; then
    url=$(echo "$url" | sed 's|https://github.com/|git@github.com:|')
  fi

  if tiged "$url" "$dir_path"; then
    $EDITOR "$dir_path"
    return 0
  else
    printf "%b\n" "$_red""Failed to clone repository$_reset"
    return 1
  fi
}

function git_clone_with_all_branches() {
  local flag_help flag_path flag_name flag_https
  local dir_path="${CODE_PERSONAL:-$PWD}"
  local usage=(
    "git_clone_with_all_branches [-h|--help] [-p|--path <path>] [-n|--name <name>] [--https]"
    "  -h, --help     Show this help message"
    "  -p, --path     Specify output directory (default: $dir_path)"
    "  -n, --name     Specify project name"
    "     --https     Use HTTPS instead of SSH (default: SSH)"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {p,-path}:=flag_path \
    {n,-name}:=flag_name \
    -https=flag_https || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  is_installed git "Git is required. Please install it first." || return 1

  local url="$(chrome_get_front_window_url)"
  local repo=${url:t2}
  local project_name="${flag_name[-1]:-${repo:t}}"
  local clone_path="${flag_path[-1]:-$dir_path}/$project_name"

  # Determine if using SSH or HTTPS (SSH by default)
  local clone_url
  if [[ -n "$flag_https" ]]; then
    clone_url="https://github.com/$repo"
  else
    clone_url="git@github.com:$repo"
  fi

  if git clone --mirror "$clone_url" "$clone_path/.git"; then
    cd "$clone_path"
    git config --bool core.bare false
    git checkout dev || git checkout main || git checkout master
    return 0
  else
    printf "%b\n" "$_red""Failed to clone repository$_reset"
    return 1
  fi
}

function git_create_all_branches_from_remote_to_local() {
  local remote="${1:-origin}"
  local count=0

  for brname in $(git branch -r | grep $remote | grep -v /main | grep -v /HEAD | awk '{gsub(/^[^\/]+\//,"",$1); print $1}'); do
    if git branch --track $brname $remote/$brname 2>/dev/null; then
      ((count++))
    fi
  done

  printf "%b\n" "$_green""Created $count local tracking branches$_reset"
}

function git_track_current_branch_to_remote() {
  local branch_name="$(git_get_current_branch_name)"
  if git checkout -b "$branch_name" "origin/$branch_name"; then
    printf "%b\n" "$_green""Successfully tracked branch $branch_name$_reset"
  else
    printf "%b\n" "$_red""Failed to track branch $branch_name$_reset"
    return 1
  fi
}

function git_get_current_branch_name() {
  git rev-parse --abbrev-ref HEAD
}

function git_create_branch_and_push_origin() {
  local branch_name="$(printf "%s" ${1:l} | sed s/" "/-/g)"

  if git checkout -b "${branch_name:q}"; then
    if git push -u origin "${branch_name:q}"; then
      printf "%b\n" "$_green""Successfully created and pushed branch $branch_name$_reset"
      return 0
    else
      printf "%b\n" "$_red""Failed to push branch $branch_name$_reset"
      return 1
    fi
  else
    printf "%b\n" "$_red""Failed to create branch $branch_name$_reset"
    return 1
  fi
}

function git_create_branches_and_push_origin() {
  local branches=(${(@)@})
  local success_count=0
  local total=${#branches[@]}

  if [[ "$total" -eq "1" ]]; then
    git_create_branch_and_push_origin "${branches[1]}"
    return $?
  fi

  for branch in "${branches[@]}"; do
    local branch_name_formatted="$(trim ${branch})"
    if git_create_branch_and_push_origin "$branch_name_formatted"; then
      ((success_count++))
    fi
  done

  printf "%b\n" "$_green""Successfully created $success_count out of $total branches$_reset"
  [[ "$success_count" -eq "$total" ]] && return 0 || return 1
}

function git_delete_branch_local_and_origin() {
  local branch_name="$(echo ${1:l} | sed s/" "/-/g)"

  if git branch --delete "${branch_name:q}"; then
    if git push origin --delete "${branch_name:q}"; then
      printf "%b\n" "$_green""Successfully deleted branch $branch_name locally and remotely$_reset"
      return 0
    else
      printf "%b\n" "$_red""Failed to delete remote branch $branch_name$_reset"
      return 1
    fi
  else
    printf "%b\n" "$_red""Failed to delete local branch $branch_name$_reset"
    return 1
  fi
}

function git_delete_branches_local_and_origin() {
  local branches=(${(@)@})
  local success_count=0
  local total=${#branches[@]}

  for branch in "${branches[@]}"; do
    local branch_name_formatted="$(trim ${branch})"
    if git_delete_branch_local_and_origin "${branch_name_formatted}"; then
      ((success_count++))
    fi
  done

  printf "%b\n" "$_green""Successfully deleted $success_count out of $total branches$_reset"
  [[ "$success_count" -eq "$total" ]] && return 0 || return 1
}

function git_create_readme_if_not_exists() {
  # Check if README.md exists (case insensitive)
  if [[ -f "README.md" || -f "readme.md" ]]; then
    printf "\n%b\n" "$_yellow""README.md already exists, skipping creation$_reset"
    return 0
  fi

  local repo_name="${${PWD:t}%%.*}"

  # Capitalize repo name using zsh parameter expansion
  local title="${(C)${repo_name}}"

  title="${title//-/ }"
  title="${title//_/ }"

  printf "# %s\n" "$title" > README.md

  printf "%b\n" "$_green""Created README.md with title: $title$_reset"
  return 0
}

function git_init() {
  local flag_help flag_local flag_desc flag_visibility
  local usage=(
    "git_init [-h|--help] [-l|--local] [-d|--desc <description>] [-v|--visibility <public|private>]"
    "  -h, --help                 Show this help message"
    "  -l, --local               Initialize local repository only"
    "  -d, --desc                Repository description"
    "  -v, --visibility          Repository visibility (public/private, default: private)"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {l,-local}=flag_local \
    {d,-desc}:=flag_desc \
    {v,-visibility}:=flag_visibility || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  local repo_visibility="${flag_visibility[-1]:-private}"
  local repo_description="${flag_desc[-1]:-}"
  local commit_message="chore: project initialization"

  [[ -n "$repo_description" ]] && commit_message="chore: initial commit\n\n$repo_description"

  # Validate visibility
  if [[ "$repo_visibility" != "private" && "$repo_visibility" != "public" ]]; then
    printf "\n%b\n" "$_red""Invalid visibility. Use 'public' or 'private'$_reset"
    return 1
  fi

  # Check if already in a git repository
  if git rev-parse --git-dir > /dev/null 2>&1; then
    printf "\n%b\n" "$_green""Repository already initialized!$_reset"
  else
    # Initialize local repository
    printf "\n%b\n" "$_green""Initializing local repository...$_reset"
    git init || { printf "\n%b\n" "$_red""Failed to initialize git repository$_reset"; return 1 }
  fi

  git_create_readme_if_not_exists

  # # Ensure we're starting with branch "main"
  # printf "\n%b\n" "$_green""Setting up main branch...$_reset"
  # git checkout -b main

  # Check for gh CLI
  is_installed gh "GitHub CLI (gh) is required for remote repository creation" || return 1

  printf "\n%b\n" "$_green""Creating remote repository...$_reset"

  if ! gh repo create --source=. --"$repo_visibility" --description="$repo_description" --remote=origin; then
    printf "\n%b\n" "$_red""Failed to create GitHub repository$_reset"
    return 1
  fi

  # Check if directory is empty (excluding .git)
  if [[ -n "$(ls -A | grep -v '^.git$')" ]]; then
    printf "\n%b\n" "$_green""Files detected, creating initial commit...$_reset"
    if git_add_all_commit "$commit_message"; then
      printf "\n%b\n" "$_green""Pushing initial commit...$_reset"
      if ! git push -u origin main; then
        printf "\n%b\n" "$_red""Failed to push to remote repository$_reset"
        return 1
      fi
    fi
  else
    printf "\n%b\n" "$_yellow""Directory is empty, skipping initial commit$_reset"
  fi

  printf "\n%b\n" "$_green""Repository initialized successfully!$_reset"
  printf "\n%b\n" "$_green""Current branch: $_yellow$(git_get_current_branch_name)$_reset"
  printf "%b\n" "$_green""Remote URL: $_yellow$(git_get_remote_url_from_cwd_as_https)$_reset"
}

function git_is_main_or_master() {
  ! git rev-parse --abbrev-ref master >/dev/null 2>/dev/null &&
    printf "%s" 'main' || printf "%s" 'master'
}

function git_get_remote_url_from_cwd_as_ssh() {
  local url="$(git config --get remote.origin.url)"
  [[ -z "$url" ]] && { printf "%b\n" "$_red""No remote URL found$_reset"; return 1 }
  printf "%s\n" "$url"
}

function git_get_remote_url_from_cwd_as_https() {
  local url="$(git config --get remote.origin.url)"
  [[ -z "$url" ]] && { printf "%b\n" "$_red""No remote URL found$_reset"; return 1 }

  # Convert SSH URL to HTTPS
  if [[ "$url" =~ ^git@ ]]; then
    url=$(echo "$url" | sed 's/^git@\(.*\):/https:\/\/\1\//')
  fi

  printf "%s\n" "${url%.git}"
}

function git_get_remote_url_to_clipboard() {
  local url="$(git config --get remote.origin.url)"
  if [[ -z "$url" ]]; then
    printf "%b\n" "$_red""No remote URL found$_reset"
    return 1
  fi
  printf "%s" "$url" | pbcopy
  printf "%b\n" "$_green""URL copied to clipboard > $url$_reset"
}

function git_set_remote_url_from_cwd() {
  local flag_help flag_https
  local usage=(
    "git_set_remote_url_from_cwd [-h|--help] [--https]"
    "  -h, --help    Show this help message"
    "     --https    Use HTTPS instead of SSH (default: SSH)"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    -https=flag_https || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  local dir=$(basename $(pwd))
  local github_username="theodrosyimer"  # You might want to make this configurable

  # Determine URL format (SSH by default)
  local url
  if [[ -n "$flag_https" ]]; then
    url="https://github.com/$github_username"
  else
    url="git@github.com:$github_username"
  fi

  local full_url="$url/$dir.git"
  printf "%s\n" "$full_url"

  if git remote add origin "$full_url"; then
    printf "%b\n" "$_green""Successfully added remote origin$_reset"
    return 0
  else
    printf "%b\n" "$_red""Failed to add remote origin$_reset"
    return 1
  fi
}

function git_open_project_at_gh() {
  local remote_url="$(git_get_remote_url_from_cwd_as_ssh)"
  [[ $? -ne 0 ]] && return 1

  local url
  if contains "gp:" "$remote_url"; then
    url="$(echo $remote_url | sed s/gp:/https:\\/\\/github.com\\//g)"
  elif contains "git@github.com:" "$remote_url"; then
    url="$(echo $remote_url | sed s/git@github.com:/https:\\/\\/github.com\\//g)"
  else
    url="$remote_url"
  fi

  url="${url%.git}"  # Remove .git suffix if present
  open "$url"
}

function git_open_current_branch_remote_at_gh() {
  local remote_url="$(git_get_remote_url_from_cwd_as_ssh)"
  [[ $? -ne 0 ]] && return 1

  local current_branch="$(git_get_current_branch_name)"
  remote_url="${remote_url%.git}"  # Remove .git suffix if present

  local url
  if contains "gp:" "$remote_url"; then
    url="$(echo $remote_url | sed s/gp:/https:\\/\\/github.com\\//g)"
  elif contains "git@github.com:" "$remote_url"; then
    url="$(echo $remote_url | sed s/git@github.com:/https:\\/\\/github.com\\//g)"
  else
    url="$remote_url"
  fi

  open "$url/tree/$current_branch"
}

function get_file_content_from_repo() {
  local flag_help flag_owner flag_repo flag_path
  local usage=(
    "get_file_content_from_repo [-h|--help] [-o|--owner <owner>] [-r|--repo <repo>] [-p|--path <path>]"
    "  -h, --help     Show this help message"
    "  -o, --owner    Repository owner"
    "  -r, --repo     Repository name"
    "  -p, --path     File path in repository"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {o,-owner}:=flag_owner \
    {r,-repo}:=flag_repo \
    {p,-path}:=flag_path || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  local owner="${flag_owner[-1]}"
  local repo="${flag_repo[-1]}"
  local path="${flag_path[-1]}"

  if [[ -z "$owner" || -z "$repo" ]]; then
    printf "%b\n" "$_red""Owner and repository are required$_reset"
    return 1
  fi

  local api_url="https://api.github.com/repos/$owner/$repo/contents/$path"
  curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$api_url"
}

function git_branch_rename() {
  local flag_help flag_old flag_new
  local usage=(
    "git_branch_rename [-h|--help] [-o|--old <old_name>] [-n|--new <new_name>]"
    "  -h, --help     Show this help message"
    "  -o, --old      Old branch name"
    "  -n, --new      New branch name"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {o,-old}:=flag_old \
    {n,-new}:=flag_new || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  local old_branch="${flag_old[-1]}"
  local new_branch="${flag_new[-1]}"

  if [[ -z "$old_branch" || -z "$new_branch" ]]; then
    printf "\n%b\n" "$_red""Old and new branch names are required$_reset"
    return 1
  fi

  # Check if old branch exists
  if ! git show-ref --verify --quiet refs/heads/$old_branch; then
    printf "\n%b\n" "$_red""Branch '$old_branch' does not exist$_reset"
    return 1
  fi

  # Rename local branch
  if git branch -m $old_branch $new_branch; then
    printf "\n%b\n" "$_green""Renamed local branch from '$old_branch' to '$new_branch'$_reset"
  else
    printf "\n%b\n" "$_red""Failed to rename local branch$_reset"
    return 1
  fi

  # Delete old remote branch and push new one
  if git push origin --delete $old_branch; then
    printf "\n%b\n" "$_green""Deleted old remote branch '$old_branch'$_reset"
  else
    printf "\n%b\n" "$_yellow""No remote branch '$old_branch' to delete$_reset"
  fi

  if git push -u origin $new_branch; then
    printf "\n%b\n" "$_green""Pushed new branch '$new_branch' to remote$_reset"
    return 0
  else
    printf "\n%b\n" "$_red""Failed to push new branch to remote$_reset"
    return 1
  fi
}

# Aliases
alias ginit=git_init
alias gop='git_open_project_at_gh'
alias gob='git_open_current_branch_remote_at_gh'
alias gbdev=git_create_dev_branch
alias gbcreate='git_create_branches_and_push_origin'
alias gbdelete='git_delete_branches_local_and_origin'
alias gbrename='git_branch_rename'
alias gdelete='rm -rf ./.git'
alias greset='ghrd && gdelete'
alias gac='git_add_all_commit'
alias gacp='git_add_all_commit_push'
alias gc='git_clone_from_front_tab_chrome'
alias gccl='git_clone_clean_from_front_tab_chrome'
alias gccb='git_clone_clean_from_cb'
alias gcb='git_clone_with_all_branches'
alias gurl=git_get_remote_url_from_cwd_as_ssh
alias glf="git log --oneline | fzf --multi --preview 'git show {+1}'"
alias groot="git rev-parse --git-dir"
