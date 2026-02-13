alias treecode="tree_code"

function tree_code() {
  tree ${1:-.} -a --dirsfirst --gitignore -I '.git|.specstory|dist|node_modules|.expo'
}
