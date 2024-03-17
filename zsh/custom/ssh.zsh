alias mkssh=ssh_create_ssh_key
alias sshak=ssh_append_authorized_keys_to_remote

function ssh_create_ssh_key() {
  local ssh_comment

  read "ssh_comment?Enter your ssh comment: "

  [[ -z "$ssh_comment" ]] && { echo "You need to enter a comment" && return 1; }

  ssh-keygen -t ed25519 -a 100 -C "$ssh_comment" &&
    printf "%s\n" "SSH key created successfully"

  eval "$(ssh-agent -s)" && printf "%s\n" "SSH agent started successfully"

  read "ssh_key_path?Enter the path of previously created ssh key: "

  ssh-add -K $ssh_key_path && printf "%s\n" "SSH key added successfully"
}

function ssh_append_authorized_keys_to_remote() {
  local default_path=("$HOME/.ssh"/*)
  local filename ssh_destination

  [[ -z "$1" ]] && filename="$(printf '%s\n' ${default_path[@]} | fzf)" || filename="$1"

  read "ssh_destination?Enter your ssh destination: "

  [[ -z "$filename" ]] && { echo "Usage: $0 <path/to/file> <user@server_ip>" && return 1; }
  [[ -z "$ssh_destination" ]] && { echo "Usage: $0 <path/to/file> <user@server_ip>" && return 1; }

  cat "$filename" | ssh "$ssh_destination" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && sudo chattr -i ~/.ssh/authorized_keys && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sudo chattr +i ~/.ssh/authorized_keys"
}
