alias nodevu="node_version_updater"
alias nodelts="node_lts_version"
alias nodelast="node_latest_version"
alias nvmrclts="nodelts_to_nvmrc"

# corepack, pnpm and npq are installed per Node version (fnm gives each version its own
# global dir), so this must run while the *target* version is the active one. Installing
# it against the old version and then uninstalling that version leaves you with no pnpm.
function _node_install_global_tooling() {
  command npm i -g corepack@latest || {
    printf "%b\n" "$RED""Failed to install corepack$RESET" >&2; return 1
  }
  corepack enable || {
    printf "%b\n" "$RED""Failed to enable corepack$RESET" >&2; return 1
  }
  corepack enable npm || {
    printf "%b\n" "$RED""Failed to enable the corepack npm shim$RESET" >&2; return 1
  }
  corepack install -g pnpm@latest || {
    printf "%b\n" "$RED""Failed to install pnpm$RESET" >&2; return 1
  }
  command npm i -g npq || {
    printf "%b\n" "$RED""Failed to install npq$RESET" >&2; return 1
  }
}

# `p`, `pi`, `pa`, ... all expand to `NPQ_PKG_MGR=pnpm npq-hero` (see aliases.zsh), and
# npq-hero spawns the package manager through /bin/sh - so both binaries must be on PATH
# for those aliases to work. Aliases are not expanded inside a function, so `command -v`
# checks the real binaries here.
function _node_verify_tooling() {
  # NOTE: do not name this `status` - that is a read-only special parameter in zsh.
  local exit_code=0

  if command -v pnpm >/dev/null 2>&1; then
    printf "%b\n" "$GREEN""pnpm $(command pnpm -v) ready on node $(command node -v)$RESET"
  else
    printf "%b\n" "$RED""pnpm is NOT on PATH for $(command node -v) - run: corepack install -g pnpm@latest$RESET" >&2
    exit_code=1
  fi

  if ! command -v npq-hero >/dev/null 2>&1; then
    printf "%b\n" "$RED""npq-hero is NOT on PATH - the p/pnpm/npm aliases will fail. Run: npm i -g npq$RESET" >&2
    exit_code=1
  fi

  return $exit_code
}

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
    printf "%b\n\n" "$BLUE""Processing LTS version update...$RESET"

    local versions=("${(f)$(fnm list-remote --lts)}")
    local latest_lts_version=${(s: :)versions[-1]% *}
    local previous_lts_version=$(fnm list | grep "lts" | awk '{print $2}')
    local original_version=$(fnm current)

    printf "%b\n" "$CYAN""Latest LTS version: $RESET$latest_lts_version"

    # if the latest LTS version is the same as the current version, exit
    if [[ "$previous_lts_version" == "$latest_lts_version" ]]; then
      printf "%b\n" "$GREEN""Latest LTS version $latest_lts_version is already installed$RESET"
      return 0
    fi

    # Install LTS version if not already installed
    if ! fnm list | grep -q "$latest_lts_version"; then
      printf "%b\n" "$YELLOW""Installing LTS version: $RESET$latest_lts_version"
      fnm install "$latest_lts_version" || error_exit "Failed to install LTS version $latest_lts_version"
    else
      printf "%b\n" "$GREEN""LTS version $latest_lts_version already installed$RESET"
    fi

    # Update LTS alias
    fnm alias "$latest_lts_version" "lts"
    printf "%b\n" "$GREEN""Aliased 'lts' to $RESET$latest_lts_version"

    # Switch before installing the tooling so it lands on the new version, then restore
    # the version that was active before.
    fnm use "$latest_lts_version" || { error_exit "Failed to switch to LTS version $latest_lts_version"; return 1; }
    _node_install_global_tooling || { error_exit "Failed to install global tooling on $latest_lts_version"; return 1; }

    # Uninstall previous aliased "lts" version - safe now that it is not the active one
    printf "\n%b\n" "$YELLOW""Previous LTS version: $RESET$previous_lts_version"
    if [[ -n "$previous_lts_version" && "$previous_lts_version" != "$latest_lts_version" ]]; then
      printf "%b\n" "$YELLOW""Uninstalling previous LTS version: $RESET$previous_lts_version"
      fnm uninstall "$previous_lts_version" 2>/dev/null || true
    fi

    if [[ -n "$original_version" && "$original_version" != "none" && "$original_version" != "system" \
          && "$original_version" != "$latest_lts_version" ]]; then
      if [[ "$original_version" == "$previous_lts_version" ]]; then
        printf "%b\n" "$YELLOW""$original_version was uninstalled, staying on $latest_lts_version$RESET"
      else
        fnm use "$original_version"
        printf "%b\n" "$CYAN""Restored active version: $RESET$original_version"
      fi
    fi

    _node_verify_tooling || return 1
  fi

  # Handle latest version update
  if [[ -n "$flag_latest" ]]; then
    printf "%b\n\n" "$BLUE""Processing latest version update...$RESET"

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
      fnm install "$node_latest_version" || error_exit "Failed to install latest version $node_latest_version"
    else
      printf "%b\n" "$GREEN""Latest version $node_latest_version already installed$RESET"
    fi

    # Update latest alias
    fnm alias "$node_latest_version" "latest"
    printf "%b\n" "$GREEN""Aliased 'latest' to $RESET$node_latest_version"

    # Switch before installing the tooling, so corepack/pnpm/npq land on the new version
    # instead of on the old one we are about to uninstall.
    fnm use "$node_latest_version" || { error_exit "Failed to switch to latest version $node_latest_version"; return 1; }
    fnm default "$node_latest_version"
    printf "%b\n" "$GREEN""Switched to latest version: $RESET$node_latest_version"

    _node_install_global_tooling || { error_exit "Failed to install global tooling on $node_latest_version"; return 1; }

    # Uninstall previous aliased "latest" version - safe now that it is not the active one
    if [[ -n "$previous_latest_version" && "$previous_latest_version" != "$node_latest_version" ]]; then
      printf "%b\n" "$YELLOW""Uninstalling previous latest version: $RESET$previous_latest_version"
      fnm uninstall "$previous_latest_version" 2>/dev/null || true
    fi

    _node_verify_tooling || return 1
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
  echo $node_lts_version_without_v > "${1:-$PWD}/.nvmrc"
}

function nclean() {
  rm -rf node_modules
  npm cache clean --force
  npm ci
}

function pclean() {
  rm -rf node_modules
  npm cache clean --force
  pnpm install --frozen-lockfile
}
