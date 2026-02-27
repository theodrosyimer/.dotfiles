alias nodevu="node_version_updater"
alias nodelts="node_lts_version"
alias nodelast="node_latest_version"
alias nvmrclts="nodelts_to_nvmrc"

function node_version_updater() {
  local flag_help flag_lts flag_latest
  local usage=(
    "node_version_updater [-h|--help] [--lts] [--latest]"
    "  -h, --help     Show this help message"
    "     --lts       Update to latest LTS version (default)"
    "     --latest    Update to latest version"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    -lts=flag_lts \
    -latest=flag_latest || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0; }

  # If no flags specified, default to LTS
  if [[ -z "$flag_lts" && -z "$flag_latest" ]]; then
    flag_lts=true
  fi

  error_exit() {
    printf "%b\n" "$RED$1$RESET" >&2
    return 1
  }

  # Handle LTS version update
  if [[ -n "$flag_lts" ]]; then
    printf "%b\n" "$BLUE""Processing LTS version update...$RESET"

    local versions=("${(f)$(fnm list-remote --lts)}")
    local latest_lts_version=${(s: :)versions[-1]% *}
    local previous_lts_version=$(fnm list | grep "lts" | awk '{print $2}')

    printf "%b\n" "$CYAN""Latest LTS version: $RESET$latest_lts_version"

    # if the latest LTS version is the same as the current version, exit
    if [[ "$previous_lts_version" == "$latest_lts_version" ]]; then
      printf "%b\n" "$GREEN""Latest LTS version $latest_lts_version is already installed$RESET"
      return 0
    fi

    # Install LTS version if not already installed
    if ! fnm list | grep -q "$latest_lts_version"; then
      printf "%b\n" "$YELLOW""Installing LTS version: $RESET$latest_lts_version"
      fnm install --corepack-enabled=false "$latest_lts_version" || error_exit "Failed to install LTS version $latest_lts_version"
      command npm i -g corepack@latest && corepack enable && corepack enable npm && corepack use pnpm@latest
      command npm i -g npq
    else
      printf "%b\n" "$GREEN""LTS version $latest_lts_version already installed$RESET"
    fi

    # Uninstall previous aliased "lts" version if it exists and is not the latest LTS version
    printf "%b\n" "$YELLOW""Previous LTS version: $RESET$previous_lts_version"
    if [[ -n "$previous_lts_version" && "$previous_lts_version" != "$latest_lts_version" ]]; then
      printf "%b\n" "$YELLOW""Uninstalling previous LTS version: $RESET$previous_lts_version"
      fnm uninstall "$previous_lts_version" 2>/dev/null || true
      fnm unalias "lts" 2>/dev/null || true
    fi

    # Update LTS alias
    fnm alias "$latest_lts_version" "lts"
    printf "%b\n" "$GREEN""Aliased 'lts' to $RESET$latest_lts_version"
  fi

  # Handle latest version update
  if [[ -n "$flag_latest" ]]; then
    printf "%b\n" "$BLUE""Processing latest version update...$RESET"

    local previous_latest_version=$(fnm list | grep "latest" | awk '{print $2}')
    local node_latest_version=$(fnm ls-remote --latest)
    printf "%b\n" "$CYAN""Latest version: $RESET$node_latest_version"

    # if the latest version is the same as the current version, exit
    if [[ "$previous_latest_version" == "$node_latest_version" ]]; then
      printf "%b\n" "$GREEN""Latest version $node_latest_version is already installed$RESET"
      return 0
    fi

    # Install latest version if not already installed
    if ! fnm list | grep -q "$node_latest_version"; then
      printf "%b\n" "$YELLOW""Installing latest version: $RESET$node_latest_version"
      fnm install --corepack-enabled=false "$node_latest_version" || error_exit "Failed to install latest version $node_latest_version"
      command npm i -g corepack@latest && corepack enable && corepack enable npm && corepack use pnpm@latest
      command npm i -g npq
    else
      printf "%b\n" "$GREEN""Latest version $node_latest_version already installed$RESET"
    fi

    # Uninstall previous aliased "latest" version if it exists and is not the latest version
    if [[ -n "$previous_latest_version" && "$previous_latest_version" != "$node_latest_version" ]]; then
      printf "%b\n" "$YELLOW""Uninstalling previous latest version: $RESET$previous_latest_version"
      fnm uninstall "$previous_latest_version" 2>/dev/null || true
      fnm unalias "latest" 2>/dev/null || true
    fi

    # Update latest alias
    fnm alias "$node_latest_version" "latest"
      printf "%b\n" "$GREEN""Aliased 'latest' to $RESET$node_latest_version"

    # Switch to latest version if --latest was specified
    fnm use "$node_latest_version"
    fnm default "$node_latest_version"
    printf "%b\n" "$GREEN""Switched to latest version: $RESET$node_latest_version"
  fi
}

function node_latest_version() {
  local node_latest_version=$(fnm ls-remote --latest)
  printf '%s' ${node_latest_version}
}

function node_lts_version() {
  local versions=("${(f)$(fnm list-remote --lts)}")
  local latest_lts_version=${(s: :)versions[-1]% *}
  printf '%s' ${latest_lts_version}
}

function fnm_remove() {
  if [[ $#@ -eq 0 ]]; then
    printf '%s\n' 'You need to enter one or more node versions'
    return 1
  fi

	for file in "$@[@]"; do
    fnm uninstall $file
  done
}

function nodelts_to_nvmrc() {
  local node_lts_version=$(node_lts_version)
  local node_lts_version_without_v=$(echo ${node_lts_version:1})
  echo $node_lts_version_without_v > .nvmrc
}

function nclean() {
  rm -rf node_modules
  npm cache clean --force
  npm install
}

function pclean() {
  rm -rf node_modules
  npm cache clean --force
  pnpm install
}
