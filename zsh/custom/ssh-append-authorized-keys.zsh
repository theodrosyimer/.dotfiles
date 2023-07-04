function ssh_append_authorized_keys() {
  local FILENAME=$1
  local SERVER_ALIAS=$2
  # local USERNAME=$2
  # local SERVER_IP=$3

  cat "~/.ssh/$FILENAME.pub" | ssh "$SERVER_ALIAS" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && sudo chattr -i ~/.ssh/authorized_keys && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sudo chattr +i ~/.ssh/authorized_keys "
}
