alias macosv=get_macos_version

function get_macos_version() {
  printf "${$(sw_vers -productVersion)%%.*}"
  # echo hello
}

# function pls() {
# 	lsof -nPi | rg -i $@
# }

