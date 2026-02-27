alias mkssh=ssh_create_ssh_key
alias sshak=ssh_append_authorized_keys_to_remote

source "$ZSH_CUSTOM/colorize.zsh"

# Creates an Ed25519 SSH key, starts the ssh-agent, and adds the key.
# ! Works on macOS and Linux (should work for Windows using WSL2 or Git Bash)
function ssh_create_ssh_key() {
  local ssh_label ssh_key_path ssh_key_path_pub label_sanitized default_filename
  local ssh_dir="$HOME/.ssh"

  # Safety prompt before modifying SSH directory
  printf "\n%s\n\n" "$YELLOW""WARNING: This script will create/modify your SSH directory ($ssh_dir) to have the correct permissions (700) and generate a new SSH key.""$RESET"
  read -r "continue_prompt?$CYAN""Do you want to continue? $WHITE""(y/N): ""$RESET"
  printf "\n"
  if [[ ! "$continue_prompt" =~ ^[Yy]$ ]]; then
    printf "%s\n" "$RED""SSH key creation aborted.""$RESET"
    return 1
  fi

  # Ensure .ssh directory exists with correct permissions
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  # Prompt for SSH key label
  read -r "ssh_label?Enter a label for your new SSH key (e.g., user@hostname): "
  if [[ -z "$ssh_label" ]]; then
    printf "\n%s" "Error: SSH key label cannot be empty." >&2
    return 1
  fi

  # Suggest a filename based on the label
  label_sanitized=$(echo "$ssh_label" | tr -c '[:alnum:]_.' '_') # Sanitize label for filename
  default_filename="${label_sanitized%?}_id_ed25519"
  read -r "ssh_key_path?Enter the path and filename for the new key [${default_filename}]: "

  ssh_key_path="${ssh_dir}/${ssh_key_path:-$default_filename}"
  ssh_key_path_pub="${ssh_key_path}.pub"

  # Check if key files already exist
  if [[ -e "$ssh_key_path" || -e "$ssh_key_path_pub" ]]; then
    printf "\n%s" "Error: SSH key files already exist: '$ssh_key_path' or '$ssh_key_path_pub'." >&2
    read -r "overwrite?Overwrite existing files? (y/N): "
    if [[ "$overwrite" =~ ^[Nn]$ ]]; then
      printf "\n%s" "Aborting."
      return 1
    fi
  fi

  # Generate the SSH key
  if ssh-keygen -t ed25519 -a 100 -C "$ssh_label" -f "$ssh_key_path"; then
    printf "%s" "SSH key created successfully: $ssh_key_path"
    printf "%s" "Public key: $ssh_key_path_pub"
  else
    printf "\n%s" "Error: ssh-keygen failed." >&2
    return 1
  fi

  # Start ssh-agent if not already running
  if ! ssh-add -l &>/dev/null; then
    printf "\n%s" "Starting ssh-agent..."
    # Capture output/errors from ssh-agent
    local agent_output agent_pid
    agent_output=$(ssh-agent -s)
    if [[ $? -ne 0 ]]; then
        printf "\n%s" "Error: Failed to start ssh-agent." >&2
        printf "\n%s" "Output: $agent_output"
        return 1
    fi
    eval "$agent_output"
    agent_pid=$SSH_AGENT_PID
    if [[ -n "$agent_pid" ]]; then
        printf "\n%s" "SSH agent started successfully (PID: $agent_pid)!"
    else
        printf "\n%s" "Warning: ssh-agent started but could not confirm PID." >&2
    fi
  else
    printf "\n%s" "SSH agent is already running."
  fi


  printf "\n%s" "Adding SSH key to the agent..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # Use `cut` to be more robust than `%%.*`
    local macos_version
    macos_version=$(sw_vers -productVersion | cut -d. -f1)
    if [[ "$macos_version" -ge 12 ]]; then
      # macOS 12+
      if ssh-add --apple-use-keychain "$ssh_key_path"; then
        printf "\n%s" "SSH key added successfully to agent and macOS Keychain!"
      else
        printf "\n%s" "Error: Failed to add SSH key using '--apple-use-keychain'." >&2
        return 1
      fi
    else
      # Older macOS versions (11 and below)
      if ssh-add -K "$ssh_key_path"; then
         printf "\n%s" "SSH key added successfully to agent and legacy macOS Keychain!"
      else
        printf "\n%s" "Error: Failed to add SSH key using '-K'." >&2
        return 1
      fi
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ssh-add "$ssh_key_path"; then
      printf "\n%s" "SSH key added successfully to agent!"
    else
      printf "\n%s" "Error: Failed to add SSH key using 'ssh-add'." >&2
      return 1
    fi
  else
    printf "\n%s" "Warning: Unsupported OS '$OSTYPE'. Cannot automatically add key to keychain/agent persistence. Key added to current agent session only."
    if ! ssh-add "$ssh_key_path"; then
       printf "\n%s" "Error: Failed to add SSH key using 'ssh-add'." >&2
       return 1
    fi
  fi

  # Print the public key content for easy copying
  if [[ -f "$ssh_key_path_pub" ]]; then
    printf "\n%s\n" "Public key:"
    cat "$ssh_key_path_pub"
    printf "\n"
  fi

  return 0
}

# * Dependency: fzf (optional, falls back to `select`)
# Appends a specified public SSH key to the authorized_keys file on a remote server.
function ssh_append_authorized_keys_to_remote() {
  local pub_key_file ssh_destination pub_key_content remote_cmd
  local ssh_dir="$HOME/.ssh"
  local pub_key_files=("$ssh_dir"/*.pub(N)) # (N) for nullglob if no matches

  # Check if a file path was provided as an argument
  if [[ -n "$1" && -f "$1" && "$1" == *.pub ]]; then
    pub_key_file="$1"
    echo "Using provided public key file: $pub_key_file"
  elif [[ ${#pub_key_files[@]} -eq 0 ]]; then
     echo "Error: No .pub files found in $ssh_dir" >&2
     return 1
  else
    # Select public key file
    echo "Select the public key file to send:"
    if command -v fzf >/dev/null; then
      pub_key_file=$(printf '%s' "${pub_key_files[@]}" | fzf --prompt="Select public key: ")
    else
       # Fallback to zsh select
       select file in "${pub_key_files[@]}" "Cancel"; do
         if [[ "$file" == "Cancel" ]]; then
           echo "Operation cancelled."
           return 1
         elif [[ -n "$file" ]]; then
           pub_key_file="$file"
           break
         else
            echo "Invalid selection."
         fi
       done
    fi
  fi

  # Check if a file was actually selected/provided
  if [[ -z "$pub_key_file" || ! -f "$pub_key_file" ]]; then
    echo "Error: No valid public key file selected or specified." >&2
    return 1
  fi

  # Prompt for SSH destination
  read -r "ssh_destination?Enter the SSH destination (e.g., user@server_ip): "
  if [[ -z "$ssh_destination" ]]; then
    echo "Error: SSH destination cannot be empty." >&2
    return 1
  fi

  # Read public key content
  pub_key_content=$(cat "$pub_key_file")
  if [[ -z "$pub_key_content" ]]; then
      echo "Error: Could not read or empty public key file: $pub_key_file" >&2
      return 1
  fi

  # Construct the remote command
  # Note: Using `sudo chattr` requires the remote user to have passwordless sudo rights for chattr.
  # This might fail or prompt for a password if not configured.
  remote_cmd=$(cat <<EOF
mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
touch ~/.ssh/authorized_keys && \
if ! grep -qFx "$pub_key_content" ~/.ssh/authorized_keys; then \
  echo 'Attempting to add key...'; \
  ( sudo chattr -i ~/.ssh/authorized_keys 2>/dev/null; \
    echo "$pub_key_content" >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys && \
    sudo chattr +i ~/.ssh/authorized_keys 2>/dev/null && \
    echo 'Key added successfully.' \
  ) || echo 'Failed to add key. Check permissions or sudo access for chattr.'; \
else \
  echo 'Key already exists in authorized_keys.'; \
fi
EOF
)

  # Execute the command remotely
  echo "Attempting to add key to $ssh_destination..."
  if ssh "$ssh_destination" "$remote_cmd"; then
    echo "Remote operation completed. Check output above for status."
  else
    echo "Error: SSH command failed. Could not connect or execute remote command." >&2
    return 1
  fi
}
