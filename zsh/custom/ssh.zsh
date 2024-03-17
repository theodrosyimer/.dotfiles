alias mkssh=ssh_create_ssh_key
alias sshak=ssh_append_authorized_keys_to_remote

# ! Only works for macos and linux (should work for windows using wsl2 or gitbash)
# * Dependency: get_macos_version -> ./system.zsh
function ssh_create_ssh_key() {
  local ssh_comment
  local macos_version="$(get_macos_version)"

  read "ssh_comment?Enter your ssh comment: "

  [[ -z "$ssh_comment" ]] && { echo "You need to enter a comment" && return 1; }

  ssh-keygen -t ed25519 -a 100 -C "$ssh_comment" &&
    printf "\n%s\n" "SSH key created successfully!"

  eval "$(ssh-agent -s)" > /dev/null && printf "\n%s\n" "SSH agent started successfully!"

  read "ssh_key_path?Enter the path of previously created ssh key: "

  if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ "$macos_version" -ge 12 ]] && ssh-add --apple-use-keychain $ssh_key_path && printf "\n%s\n" "SSH key added successfully!" && return 0

    ssh-add -K $ssh_key_path && printf "\n%s\n" "SSH key added successfully!" && return 0
  fi

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ssh-add $ssh_key_path && printf "\n%s\n" "SSH key added successfully!" && return 0
  fi
}

# * Dependency: fzf
# ? Maybe use `select` instead of fzf?
function ssh_append_authorized_keys_to_remote() {
  local default_path=("$HOME/.ssh"/*)
  local filename ssh_destination

  [[ -z "$1" ]] && filename="$(printf '%s\n' ${default_path[@]} | fzf)" || filename="$1"

  read "ssh_destination?Enter your ssh destination: "

  [[ -z "$filename" ]] && { echo "Usage: $0 <path/to/file> <user@server_ip>" && return 1; }
  [[ -z "$ssh_destination" ]] && { echo "Usage: $0 <path/to/file> <user@server_ip>" && return 1; }

  cat "$filename" | ssh "$ssh_destination" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && sudo chattr -i ~/.ssh/authorized_keys && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sudo chattr +i ~/.ssh/authorized_keys"
}
