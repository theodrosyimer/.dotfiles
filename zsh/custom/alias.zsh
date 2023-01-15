### Create aliases from the command line with a keybinding
#
# syntax: "alias" "command" "comment"
#
# "alias"   -> required
# "command" -> required
# "comment" -> optional
#
# wrapping each string in double quotes is required, for now.
#
# if i prefer to use `exec zsh` instead of `source ~/.zshrc`,
# then set `use_exec_zsh=true`, (default)
# otherwise set `use_exec_zsh=false`

# ? add a way to add a new line when a comment is NOT empty
# ? even if `add_new_lines_between_aliases=false` AND `add_new_line_only_if_comment=false`
# ?
# ? add the use of single quotes
function _add_alias() {
  local use_exec_zsh=true
  local add_new_lines_between_aliases=false
  local add_new_line_only_if_comment=true
  local buffer=$BUFFER

  [[ "${${BUFFER}[1]}" = "\"" ]] && local str="$(echo $buffer | rg -No --no-column '^(")(.*)(")$' -r $1 $3 '$2' | awk 'BEGIN {FS = "\" \""} {print $1"\n"$2"\n"$3}')"

  # [[ "${${BUFFER}[1]}" = "'" ]] && local str="$(echo $buffer | rg -No --no-column "^(')(.*)(')$" -r $1 $3 '$2' | awk 'BEGIN {FS = "' '"} {print $1"\n"$2"\n"$3}')"

  [[ -z "$str" ]] && return

  local args=(${(@f)str})

  [[ -z $args ]] && return

  local name="$args[1]"
  local alias="$args[2]"
  local comment="$args[3]"
  local alias_path="$ZDOTDIR/custom/aliases.zsh"
  local new_lines_between_aliases
  local new_lines_before_comment

  [[ -z "$name" ]] && return 1
  [[ -z "$alias" ]] && return 1
  [[ ! -f "$alias_path" ]] && return 1

  if [[ $add_new_lines_between_aliases = true ]]; then
    new_lines_between_aliases="\n"
  else
    new_lines_between_aliases=
  fi

  # if comment is a space, then set it to "\n"
  # to provide a way to add a new line
  # even if `add_new_lines_between_aliases=false` AND `add_new_line_only_if_comment=false`
  if [[ ! -z "$comment" ]] && [[ "$comment" = " " ]] && { \
    [[ $add_new_lines_between_aliases = false ]] && comment="\n" || \
    comment=; }

  if [[ ! -z "$comment" ]] && [[ "$comment" != "\n" ]] && [[ "$comment" != " " ]] && comment="# $args[3]\n"; then
    if [[ $add_new_line_only_if_comment = true ]]; then
      new_lines_before_comment="\n"
    else
      new_lines_before_comment=
    fi
  fi

  if [[ -z "$comment" ]] && comment=; then
      new_lines_before_comment=
  fi

  printf "%b\n" \
    "$new_lines_between_aliases$new_lines_before_comment"$comment"alias "$name"=\""$alias"\"" >>"$alias_path"

  zle backward-kill-line
  zle reset-prompt
  zle clear-screen

  [[ $use_exec_zsh = true ]] && zle _exec_zsh || source ~/.zshrc
}

zle -N _add_alias
bindkey -v
bindkey '^[a' _add_alias

# Search and Filter aliases
function aliass() {
  alias | 'rg' "$@" --sort path
}

