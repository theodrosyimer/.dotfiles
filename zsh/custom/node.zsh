alias nodevu="node_version_updater"
alias nodelts="node_lts_version"
alias nodelv="node_latest_version"

function node_version_updater() {
  local flag_help flag_lts flag_latest
  local usage=(
    "node_version_updater [-h|--help] [--lts] [--latest]"
    "  -h, --help     Show this help message"
    "     --lts       Update to latest LTS version"
    "     --latest    Update to latest version"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    -lts=flag_lts \
    -latest=flag_latest || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0 }

  # If no flags specified, default to LTS
  if [[ -z "$flag_lts" && -z "$flag_latest" ]]; then
    flag_lts=true
  fi

  # Function to handle errors
  error_exit() {
    printf "%b\n" "$_red$1$_reset" >&2
    return 1
  }

  # Handle LTS version update
  if [[ -n "$flag_lts" ]]; then
    printf "%b\n" "$_blue""Processing LTS version update...$_reset"

    local versions=("${(f)$(fnm list-remote --lts)}")
    local latest_lts_version=${(s: :)versions[-1]% *}
    local previous_lts_version=$(fnm list | grep "lts" | awk '{print $2}')

    printf "%b\n" "$_cyan""Latest LTS version: $_reset$latest_lts_version"

    # if the latest LTS version is the same as the current version, exit
    if [[ "$previous_lts_version" == "$latest_lts_version" ]]; then
      printf "%b\n" "$_green""Latest LTS version $latest_lts_version is already installed$_reset"
      return 0
    fi

    # Install LTS version if not already installed
    if ! fnm list | grep -q "$latest_lts_version"; then
      printf "%b\n" "$_yellow""Installing LTS version: $_reset$latest_lts_version"
      fnm install "$latest_lts_version" || error_exit "Failed to install LTS version $latest_lts_version"
    else
      printf "%b\n" "$_green""LTS version $latest_lts_version already installed$_reset"
    fi

    # Uninstall previous aliased "lts" version if it exists and is not the latest LTS version
    printf "%b\n" "$_yellow""Previous LTS version: $_reset$previous_lts_version"
    if [[ -n "$previous_lts_version" && "$previous_lts_version" != "$latest_lts_version" ]]; then
      printf "%b\n" "$_yellow""Uninstalling previous LTS version: $_reset$previous_lts_version"
      fnm uninstall "$previous_lts_version" 2>/dev/null || true
      fnm unalias "lts" 2>/dev/null || true
    fi

    # Update LTS alias
    fnm alias "$latest_lts_version" "lts"
    printf "%b\n" "$_green""Aliased 'lts' to $_reset$latest_lts_version"
  fi

  # Handle latest version update
  if [[ -n "$flag_latest" ]]; then
    printf "%b\n" "$_blue""Processing latest version update...$_reset"

    local previous_latest_version=$(fnm list | grep "latest" | awk '{print $2}')
    local node_latest_version=$(fnm ls-remote --latest)
    printf "%b\n" "$_cyan""Latest version: $_reset$node_latest_version"

    # if the latest version is the same as the current version, exit
    if [[ "$previous_latest_version" == "$node_latest_version" ]]; then
      printf "%b\n" "$_green""Latest version $node_latest_version is already installed$_reset"
      return 0
    fi

    # Install latest version if not already installed
    if ! fnm list | grep -q "$node_latest_version"; then
      printf "%b\n" "$_yellow""Installing latest version: $_reset$node_latest_version"
      fnm install "$node_latest_version" || error_exit "Failed to install latest version $node_latest_version"
    else
      printf "%b\n" "$_green""Latest version $node_latest_version already installed$_reset"
    fi

    # Uninstall previous aliased "latest" version if it exists and is not the latest version
    if [[ -n "$previous_latest_version" && "$previous_latest_version" != "$node_latest_version" ]]; then
      printf "%b\n" "$_yellow""Uninstalling previous latest version: $_reset$previous_latest_version"
      fnm uninstall "$previous_latest_version" 2>/dev/null || true
      fnm unalias "latest" 2>/dev/null || true
    fi

    # Update latest alias
    fnm alias "$node_latest_version" "latest"
    printf "%b\n" "$_green""Aliased 'latest' to $_reset$node_latest_version"

    # Switch to latest version if --latest was specified
    fnm use "$node_latest_version"
    fnm default "$node_latest_version"
    printf "%b\n" "$_green""Switched to latest version: $_reset$node_latest_version"
  fi
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


function node_latest_version() {
  local node_latest_version=$(fnm ls-remote --latest)
  printf '%s' ${node_latest_version}
}

function node_lts_version() {
  local versions=("${(f)$(fnm list-remote --lts)}")
  local latest_lts_version=${(s: :)versions[-1]% *}
  printf '%s' ${latest_lts_version}
}
