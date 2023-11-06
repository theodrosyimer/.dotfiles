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

  local dir_path="${1:-"${CODE_PROJECTS:-"$(pwd)"}"}"
  # local dir_path="${1:-"$(pwd)"}"

  local url="$(chrome_get_front_window_url)"
  local repo=${url:t2}
  local project_name=${2:-"${repo:t}"}

  tiged "git@github.com:$repo" "$dir_path/$project_name" && code -gn "$dir_path/$project_name"
}

# ! dependency: is_installed.zsh -> available in the repository
# ! dependency: chrome.zsh -> available in the repository
# ! dependency: `git`
# ! you need NODEJS installed to use npm
# TODO: check if user uses ssh or https
# TODO: add output_path as a flag
function git_clone_from_front_tab_chrome() {
  is_installed git "You need to install git!" || return 1

  local dir_path="${1:-"${CODE_PROJECTS:-"$(pwd)"}"}"
  # local dir_path="${1:-"$(pwd)"}"

  local url="$(chrome_get_front_window_url)"
  local repo=${url:t2}


  # local flag_help flag_name
  # local output_path=("${PWD}\/my-file.txt") # sets a default path
  # local usage=(
  # "git_clone_from_tab_chrome [ -h | --help ]"
  # "git_clone_from_tab_chrome [ - | -- ] [ -o | --output <path/to/file> ]"
  # )

  # zmodload zsh/zutil
  # zparseopts -D -F -K -E -- \
  #   {h,-help}=flag_help \
  #   {n,-name}=flag_name \
  #   {o,-output}:=output_path || return 1

  # [[ -n "$flag_help" ]] && { print -l $usage && return; }

  # [[ -n "$flag_name" ]] && {  git clone "git@github.com:$repo" "$dir_path/$flag_name" && code -gn "$dir_path/$flag_name" && return; }

  local project_name=${2:-"${repo:t}"}

  git clone "git@github.com:$repo" "$dir_path/$project_name" && code -gn "$dir_path/$project_name"
}

# ! dependency: is_installed.zsh -> available in the repository
# ! dependency to download: tiged -> npm install -g tiged
# TODO: check if user uses ssh or https
# git clone url from clipboard (no test yet!)
function git_clone_clean_from_cb() {
  is_installed tiged "run -> npm i -g tiged" || return 1

  local url="$(pbpaste)"
    # local dir_path="${2:-"${CODE_PROJECTS:-"$(pwd)"}"}"
  local dir_path="${2:-"$(pwd)"}"

  tiged "$url" "$dir_path" && code -gn "$dir_path"
}

function git_clone_with_all_branches() {
  is_installed git "You need to install git!" || return 1

  local dir_path="${1:-"${CODE_PROJECTS:-"$(pwd)"}"}"
  # local dir_path="${1:-"$(pwd)"}"

  local url="$(chrome_get_front_window_url)"
  local repo=${url:t2}

  local project_name=${2:-"${repo:t}"}

  git clone --mirror "git@github.com:$repo" "$dir_path/$project_name/.git"
  cd "$dir_path/$project_name"
  git config --bool core.bare false
  git checkout dev || git checkout main
}

function git_create_branch_and_push_origin() {
  local branch_name="$(printf "%s" ${1:l} | sed s/" "/-/g)"

  git checkout -b "$branch_name" &&
    git push -u origin "$branch_name"
}

function git_get_current_branch_name() {
  printf "%s" "$(git rev-parse --abbrev-ref HEAD)"
}

function git_track_current_branch_from_remote() {
  branch_name="$(git_get_current_branch_name)"
  git checkout -b "$branch_name" "origin/$branch_name"
}

# ! dependency: text.zsh -> available in the repository
function git_create_branches_and_push_origin() {

  local branches=(${(@)@})

  (( "#$branches[@]" = 1 )) && git_create_branch_and_push_origin "$branches[1]"

  for branch in "${branches[@]}"
    do
      local branch_name_formatted="$(trim $branch)"
      # echo "$branch_name_formatted"

      git_create_branch_and_push_origin "$branch_name_formatted" # &&
      # git checkout dev
    done
}

function git_delete_branch_local_and_origin() {
  local branch_name="$(echo ${1:l} | sed s/" "/-/g)"

  git branch --delete "$branch_name" &&
    git push origin --delete "$branch_name"
}

# ! dependency: text.zsh -> available in the repository
function git_delete_branches_local_and_origin() {

  local branches=(${(@)@})

  for branch in "${branches[@]}"
    do
      local branch_name_formatted="$(trim $branch)"
      # echo "$branch_name_formatted"

      git_delete_branch_local_and_origin "$branch_name_formatted"
    done
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
      printf "%b\n\n" "$_green""\nCreating \"dev\" branch...$_reset" &&
      git_create_branch_and_push_origin "dev" &&
      git checkout dev &&
      printf "%b\n" "$_green""\nYour project is initialized!$_reset"
      printf "%s\n" "$_green""You are in the$_yellow dev$_reset$_green branch.$_reset"
  fi
}

function git_is_main_or_master() {
  ! git rev-parse --abbrev-ref master >/dev/null 2>/dev/null &&
    printf "%s" 'main' || printf "%s" 'master'
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

# INFO: run this function from your project's root directory
# TODO: check if user uses ssh or https
function git_set_remote_url_from_cwd() {
  local dir=$(basename $(pwd))

  # if `https` is used,
  # local url=https://github.com/<username>
  # i use `ssh` and `gp` is my `ssh` alias for github.com
  local url=git@github.com:theodrosyimer

  echo "$url/$dir.git"

  git remote add origin "$url/$dir.git"
}

# ! dependency: text.zsh -> available in the repository
function git_open_project_at_gh() {
  local remote_url="$(git_get_remote_url_from_cwd)"

  if contains "gp:" $remote_url; then
    local url="$(echo $remote_url | sed s/gp:/https:\\/\\/github.com\\//g)"
  fi

  if $(contains "git@github.com:" $remote_url); then
    local url="$(echo $remote_url | sed s/git@github.com:/https:\\/\\/github.com\\//g)"
  fi

  open $url
}
# # ! dependency: text.zsh -> available in the repository
# function git_open_main_or_master_remote_at_gh() {
#   local remote_url="$(git_get_remote_url_from_cwd)"

#   if contains "gp:" $remote_url; then
#     local url="$(echo $remote_url | sed s/gp:/https:\\/\\/github.com\\//g)"
#   fi

#   if $(contains "git@github.com:" $remote_url); then
#     local url="$(echo $remote_url | sed s/git@github.com:/https:\\/\\/github.com\\//g)"
#   fi

#   open $url
# }

# ! dependency: text.zsh -> available in the repository
function git_open_current_branch_remote_at_gh() {
  local remote_url="$(git_get_remote_url_from_cwd)"
  local current_branch="$(git rev-parse --abbrev-ref HEAD)"
  remote_url="$(echo $remote_url | sed s/.git$//g)"


  if contains "gp:" $remote_url; then
    local url="$(echo $remote_url | sed s/gp:/https:\\/\\/github.com\\//g)"
  fi

  if $(contains "git@github.com:" $remote_url); then
    local url="$(echo $remote_url | sed s/git@github.com:/https:\\/\\/github.com\\//g)"
  fi

  open $url/tree/$current_branch
}

alias ginit=git_init
alias gop='git_open_project_at_gh'
# alias gom='git_open_main_or_master_remote_at_gh'
alias gob='git_open_current_branch_remote_at_gh'
alias gbcreate='git_create_branches_and_push_origin'
alias gbdelete='git_delete_branches_local_and_origin'

# run this function from your project's root directory
alias gdelete='rm -rf ./.git'
# or the safer version
# 'rm -ri ./.git'

# run this function from your project's root directory
# delete local .git folder and remote github repo
alias greset='ghrd && gdelete'

alias gac='git_add_all_commit'
alias gacp='git_add_all_commit_push'

alias gc='git_clone_from_front_tab_chrome'
alias gcc='git_clone_clean_from_front_tab_chrome'
alias gccb='git_clone_clean_from_cb'

alias gurl=git_get_remote_url_from_cwd
alias glf="git log --oneline | fzf --multi --preview 'git show {+1}'"
