# tree.zsh — Git-aware directory tree with clipboard support
#
# Prints a directory tree excluding common ignored folders (.git, node_modules, etc.)
# and copies output to clipboard. Use --show to print to terminal instead.
#
# Dependencies: tree
# Provided by oh-my-zsh auto-sourcing $ZSH_CUSTOM/*.zsh

alias treecode="tree_code"

function tree_code() {
  local flag_help flag_show
  local flag_level=("3")
  local flag_input=(".")
  local usage=(
    "tree_code [-h|--help] [-s|--show] [-L|--level <n>] [-o|--output <dir>]"
    ""
    "Prints a git-aware directory tree, excluding common ignored folders, and copies it to the clipboard."
    ""
    "  -h, --help         Show this help message"
    "  -i, --input <dir>  Directory to tree (default: .)"
    "  -l, --level <n>    Limit tree depth to n levels (default: ${flag_level[-1]})"
    "  -s, --show         Print the tree output to the terminal instead of copying to clipboard"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -E -- \
    {h,-help}=flag_help \
    {s,-show}=flag_show \
    {l,-level}:=flag_level \
    {i,-input}:=flag_input || return 1

  [[ -n "$flag_help" ]] && { print -l $usage; return 0; }

  [[ -n "$flag_level" && ! "$flag_level[-1]" =~ ^[0-9]+$ ]] && {
    echo "Error: --level requires a number" >&2; return 1
  }

  local tree_args=("$flag_input[-1]" -a --dirsfirst --gitignore -I '.git|.specstory|dist|node_modules|.expo|.turbo|.next|.vercel|.cache|.vscode|.idea')
  [[ -n "$flag_level" ]] && tree_args+=(-L "$flag_level[-1]")

  local tree_output
  tree_output=$(tree "${tree_args[@]}" 2>/dev/null)

  if [[ -n "$flag_show" ]]; then
    printf "%s" "$tree_output"
  else
    printf "%s" "$tree_output" | pbcopy
  fi
}
