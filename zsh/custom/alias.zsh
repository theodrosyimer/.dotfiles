### Create aliases from the command line
#
# syntax: "alias" "command" "comment"
#
# "alias"   -> required
# "command" -> required
# "comment" -> optional
#
# double quotes are required, for now.

# ? add the use of single quotes
function _aa() {
  local buffer=$BUFFER
  local str="$(echo $buffer | rg -No --no-column '^(")(.*)(")$' -r $1 $3 '$2' | awk 'BEGIN {FS = "\" \""} {print $1"\n"$2"\n"$3}')"
  local args=(${(@f)str})

  [[ -z $args ]] && return

  local name="$args[1]"
  local alias="$args[2]"
  local comment_extract="$args[3]"
  local comment=${comment_extract:-}

  [[ "$args[3]" != "# Add a description" ]] && comment="# "$args[3]""

  echo "\n"$comment"\nalias "$name"=\""$alias"\"" >>$ZSH_CUSTOM/aliases.zsh

  zle backward-kill-line
  zle reset-prompt
  zle clear-screen

  # echo "\r" #¯\_(ツ)_/¯
  # zle redisplay
  zle _exec_zsh
}

zle -N _aa
bindkey -v
bindkey '^[a' _aa

# Search and Filter aliases
function aliass() {
  alias | 'rg' "$@" --sort path
}

