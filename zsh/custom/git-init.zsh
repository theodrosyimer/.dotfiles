function git_create_readme_if_not_exists() {
  if [[ -f "README.md" || -f "readme.md" ]]; then
    printf "\n%b\n" "$YELLOW""README.md already exists, skipping creation$RESET"
    return 0
  fi

  local repo_name="${${PWD:t}%%.*}"

  local title="${(C)${repo_name}}"

  title="${title//-/ }"
  title="${title//_/ }"

  printf "# %s\n" "$title" > README.md

  printf "%b\n" "$GREEN""Created README.md with title: $title$RESET"
  return 0
}

function git_init() {
  local flag_help flag_local flag_desc flag_public flag_private flag_org flag_dry_run
  local usage=(
    "git_init [-h|--help] [-l|--local] [-d|--desc <description>] [--public|--private] [-o|--org <org>] [--dry-run]"
    ""
    "  -h, --help                 Show this help message"
    "  -l, --local               Initialize local repository only"
    "  -d, --desc                Repository description"
    "     --public               Create public repository"
    "     --private              Create private repository (default)"
    "  -o, --org                 GitHub organization (creates repo under org instead of personal)"
    "     --dry-run              Show what would be done without making any changes"
    ""
    "Examples:"
    "  ginit                              # private, personal"
    "  ginit --public                     # public, personal"
    "  ginit -o my-org                    # private, org"
    "  ginit --public -o my-org           # public, org"
    "  ginit -o my-org -d \"Cool project\"  # private, org, with description"
    "  ginit -l                           # local only, no remote"
    "  ginit --dry-run -o my-org          # preview what would happen"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {l,-local}=flag_local \
    {d,-desc}:=flag_desc \
    {o,-org}:=flag_org \
    -public=flag_public \
    -private=flag_private \
    -dry-run=flag_dry_run || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0; }

  if [[ -n "$flag_public" && -n "$flag_private" ]]; then
    printf "\n%b\n" "$RED""Cannot use both --public and --private$RESET"
    return 1
  fi

  local dry_run=false
  [[ -n "$flag_dry_run" ]] && dry_run=true

  local repo_visibility="private"
  [[ -n "$flag_public" ]] && repo_visibility="public"

  local repo_description="${flag_desc[-1]:-}"
  local org_name="${flag_org[-1]:-}"
  local commit_message="chore: project initialization"

  [[ -n "$repo_description" ]] && commit_message="chore: initial commit\n\n$repo_description"

  if [[ "$dry_run" == true ]]; then
    printf "\n%b\n" "$YELLOW""=== DRY RUN — no changes will be made ===$RESET"
  fi

  # --- Snapshot pre-existing state for rollback ---
  local had_git=false
  local had_readme=false

  [[ -d ".git" ]] && had_git=true
  [[ -f "README.md" || -f "readme.md" ]] && had_readme=true

  # Initialize local repository
  if git rev-parse --git-dir > /dev/null 2>&1; then
    printf "\n%b\n" "$GREEN""Repository already initialized!$RESET"
  else
    _git_init_run "$dry_run" "Would run: git init" \
      git init || { printf "\n%b\n" "$RED""Failed to initialize git repository$RESET"; return 1; }
  fi

  # README
  if [[ "$had_readme" == false ]]; then
    _git_init_run "$dry_run" "Would create: README.md" \
      git_create_readme_if_not_exists
  else
    printf "\n%b\n" "$GREEN""README.md already exists$RESET"
  fi

  # Local-only mode: skip remote creation
  if [[ -n "$flag_local" ]]; then
    if [[ -n "$(ls -A | grep -v '^.git$')" || "$had_readme" == false ]]; then
      _git_init_run "$dry_run" "Would commit: \"$commit_message\"" \
        git_add_all_commit "$commit_message"
    fi
    if [[ "$dry_run" == true ]]; then
      printf "\n%b\n" "$YELLOW""=== DRY RUN complete ===$RESET"
    else
      printf "\n%b\n" "$GREEN""Local repository initialized successfully!$RESET"
    fi
    return 0
  fi

  # --- Remote creation ---
  is_installed gh "GitHub CLI (gh) is required for remote repository creation" || return 1

  local repo_name="${PWD:t}"
  local repo_owner

  if [[ -n "$org_name" ]]; then
    repo_owner="$org_name"
  else
    repo_owner="$(gh api user --jq '.login' 2>/dev/null)"
    if [[ -z "$repo_owner" ]]; then
      printf "\n%b\n" "$RED""Failed to get GitHub username. Are you authenticated with gh?$RESET"
      [[ "$dry_run" == false ]] && _git_init_rollback "$had_git" "$had_readme"
      return 1
    fi
  fi

  local full_repo="$repo_owner/$repo_name"
  local repo_exists=false

  if gh repo view "$full_repo" --json name >/dev/null 2>&1; then
    repo_exists=true
  fi

  if [[ "$repo_exists" == true ]]; then
    printf "\n%b\n" "$YELLOW""Repository '$full_repo' already exists on GitHub.$RESET"

    local remote_url="git@github.com:$full_repo.git"

    if [[ "$dry_run" == true ]]; then
      # Dry run: report what would happen without prompting
      if git remote get-url origin >/dev/null 2>&1; then
        local existing_origin="$(git remote get-url origin)"
        if [[ "$existing_origin" == "$remote_url" || "$existing_origin" == "https://github.com/$full_repo.git" || "$existing_origin" == "https://github.com/$full_repo" ]]; then
          printf "\n%b\n" "$YELLOW""[dry-run] Remote origin already points to '$full_repo' — no change needed$RESET"
        else
          printf "\n%b\n" "$YELLOW""[dry-run] Would prompt to overwrite origin '$existing_origin' → '$remote_url'$RESET"
        fi
      else
        printf "\n%b\n" "$YELLOW""[dry-run] Would prompt to use existing repo, then add remote origin: $remote_url$RESET"
      fi
    else
      # Real run: interactive prompts
      printf "%b" "$YELLOW""Use it as remote origin? [y/N] $RESET"

      if read -q; then
        printf "\n"

        if git remote get-url origin >/dev/null 2>&1; then
          local existing_origin="$(git remote get-url origin)"
          if [[ "$existing_origin" == "$remote_url" || "$existing_origin" == "https://github.com/$full_repo.git" || "$existing_origin" == "https://github.com/$full_repo" ]]; then
            printf "\n%b\n" "$GREEN""Remote origin already points to '$full_repo'$RESET"
          else
            printf "\n%b\n" "$YELLOW""Remote origin exists but points to '$existing_origin'$RESET"
            printf "%b" "$YELLOW""Overwrite with '$remote_url'? [y/N] $RESET"

            if read -q; then
              printf "\n"
              git remote set-url origin "$remote_url"
              printf "\n%b\n" "$GREEN""Updated remote origin to '$remote_url'$RESET"
            else
              printf "\n"
              printf "\n%b\n" "$RED""Aborted.$RESET"
              _git_init_rollback "$had_git" "$had_readme"
              return 1
            fi
          fi
        else
          git remote add origin "$remote_url"
          printf "\n%b\n" "$GREEN""Added remote origin '$remote_url'$RESET"
        fi
      else
        printf "\n"
        printf "\n%b\n" "$RED""Aborted.$RESET"
        _git_init_rollback "$had_git" "$had_readme"
        return 1
      fi
    fi
  else
    # Repo doesn't exist — create it
    local gh_args=(--source=. --"$repo_visibility" --remote=origin)
    [[ -n "$repo_description" ]] && gh_args+=(--description="$repo_description")
    [[ -n "$org_name" ]] && gh_args+=(--push "$full_repo")

    if [[ "$dry_run" == true ]]; then
      printf "\n%b\n" "$YELLOW""[dry-run] Would create GitHub repository: $full_repo ($repo_visibility)$RESET"
      [[ -n "$repo_description" ]] && printf "%b\n" "$YELLOW""[dry-run]   description: $repo_description$RESET"
    else
      printf "\n%b\n" "$GREEN""Creating remote repository...$RESET"

      if ! gh repo create "${gh_args[@]}"; then
        printf "\n%b\n" "$RED""Failed to create GitHub repository$RESET"
        _git_init_rollback "$had_git" "$had_readme"
        return 1
      fi
    fi
  fi

  # Initial commit + push
  if [[ -n "$(ls -A | grep -v '^.git$')" || "$had_readme" == false ]]; then
    _git_init_run "$dry_run" "Would commit: \"$commit_message\"" \
      git_add_all_commit "$commit_message"

    if [[ -z "$org_name" || "$repo_exists" == true ]]; then
      _git_init_run "$dry_run" "Would push to origin/main" \
        git push -u origin main || {
          [[ "$dry_run" == false ]] && printf "\n%b\n" "$RED""Failed to push to remote repository$RESET"
          return 1
        }
    fi
  else
    printf "\n%b\n" "$YELLOW""Directory is empty, skipping initial commit$RESET"
  fi

  if [[ "$dry_run" == true ]]; then
    printf "\n%b\n" "$YELLOW""=== DRY RUN complete — no changes were made ===$RESET"
  else
    printf "\n%b\n" "$GREEN""Repository initialized successfully!$RESET"
    printf "\n%b\n" "$GREEN""Current branch: $YELLOW$(git_get_current_branch_name)$RESET"
    printf "%b\n" "$GREEN""Remote URL: $YELLOW$(git_get_remote_url_from_cwd_as_https)$RESET"
  fi
}

function _git_init_run() {
  local dry_run="$1"; shift
  local description="$1"; shift

  if [[ "$dry_run" == true ]]; then
    printf "\n%b\n" "$YELLOW""[dry-run] $description$RESET"
    return 0
  fi
  "$@"
}

function _git_init_rollback() {
  local had_git="$1"
  local had_readme="$2"

  if [[ "$had_readme" == false && -f "README.md" ]]; then
    rm -f "README.md"
    printf "%b\n" "$YELLOW""Removed created README.md$RESET"
  fi

  if [[ "$had_git" == false && -d ".git" ]]; then
    rm -rf ".git"
    printf "%b\n" "$YELLOW""Removed created .git directory$RESET"
  fi
}
