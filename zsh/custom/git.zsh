# Add all and commit with a comment
function git_add_all_commit() {
  git add -A && git commit -m "$1"
}

# Add all, commit with a comment and push
function git_add_all_commit_push() {
  git add -A && git commit -m "$1" && git push
}

# ! dependency: is_installed.zsh -> available in the repository
# ! dependency: chrome.zsh -> available in the repository
# ! dependency to download: tiged -> npm install -g tiged
# ! you need NODEJS installed to use npm
# TODO: check if user uses ssh or https
# TODO: add output_path as a flag
function git_clone_clean_from_front_tab_chrome() {
  is_installed tiged "run -> npm i -g tiged" || return 1

  local url="$(chrome_get_front_window_url)"
  local repo=${url:t2}
  local project_name=${1:-"${repo:t}"}

  local dir_path="${2:-"${CODE_PROJECTS:-"$(pwd)"}"}"

  tiged "git@github.com:$repo" "$dir_path/$project_name" && cd "$dir_path/$project_name" && code -gn .
}

# ! dependency: is_installed.zsh -> available in the repository
# ! dependency to download: tiged -> npm install -g tiged
# TODO: check if user uses ssh or https
# git clone url from clipboard (no test yet!)
function git_clone_clean_from_cb() {
  is_installed tiged "run -> npm i -g tiged" || return 1

  local url="$(pbpaste)"
  local dir_path="${1:-"${CODE_PROJECTS:-"$(pwd)"}"}"

  tiged $url $dir_path && code -gn $dir_path
}

function git_create_branch_and_push_origin() {
  local branch_name="$(echo ${1:l} | sed s/" "/-/g)"

  git checkout -b $branch_name &&
    git push -u origin $branch_name
}

# ! dependency: text.zsh -> available in the repository
# TODO finish this function
function git_create_multiple_branches() {

  local branches=(${(@)@})

  for branch in "${branches[@]}"
    do
    local branch_name_formatted="$(trim $branch)"
    echo "$branch_name_formatted"

     git_create_branch_and_push_origin $branch_name_formatted &&
     git checkout main
    #
    done
}

# get remote origin's' url from current, already initialized, working directory
function git_get_remote_url_from_cwd() {
  local url="$(git config --get remote.origin.url)"
  echo "$url"
}

# same as above but copy the url to clipboard
function git_get_remote_url_from_cb() {
  local url="$(git config --get remote.origin.url)"
  echo "$url" | pbcopy
  echo "URL copied to clipboard > ${url}"
}

# ! dependency: github.zsh -> available in the repository
# ! dependency to download `gh` cli:
# !   - macos -> brew install gh
# !   - linux -> https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
# TODO: add an option to only init local repo, without creating a remote repo
function git_init() {
  local comment='first commit'
  local repo_visibility="${1:-private}"
  local repo_description=$2

  if git rev-parse --git-dir 2>/dev/null; then
    printf "%s\n\n" "$_green""Your project is already initialized!$_reset" && cd ../ && return 1
  else
    printf "%b\n\n" "$_green""\nInitializing your project...$_reset" &&
      git init &&
      git_set_remote_url_from_cwd &&
      git_add_all_commit "$comment" &&
      printf "%b\n\n" "$_green""\nCreating remote repository...$_reset" &&
      gh_repo_create_from_cwd "$repo_visibility" "$repo_description" &&
      git push -u origin main &&
      printf "%b\n\n" "$_green""\nCreating \"dev\" branch...$_reset" &&
      git_create_branch_and_push_origin "dev" &&
      git checkout dev &&
      printf "%b\n" "$_green""\nYour project is initialized!$_reset"
      printf "%s\n" "$_green""You are in the$_yellow dev$_reset$_green branch.$_reset"
  fi
}

# ! dependency: text.zsh -> available in the repository
function git_open_remote_at_gh() {
  local remote_url="$(git_get_remote_url_from_cwd)"

  if contains "gp:" $remote_url; then
    local url="$(echo $remote_url | sed s/gp:/https:\\/\\/github.com\\//g)"
  fi

  if $(contains "git@github.com:" $remote_url); then
    local url="$(echo $remote_url | sed s/git@github.com:/https:\\/\\/github.com\\//g)"
  fi

  open $url
}

# INFO: run this function from your project's root directory
# TODO: check if user uses ssh or https
function git_set_remote_url_from_cwd() {
  local dir=$(basename $(pwd))

  # if `https` is used,
  # local url=https://github.com/<username>
  # i use `ssh` and `gp` is my `ssh` alias for github.com
  local url=gp:theodrosyimer

  echo $url/$dir.git

  git remote add origin $url/$dir.git
}

alias gi=git_init
alias gor='git_open_remote_at_gh'

# run this function from your project's root directory
alias gdel='rm -rf ./.git'
# or the safer version
# 'rm -ri ./.git'

# run this function from your project's root directory
# delete local .git folder and github repo
alias greset='ghrd && gdel'
