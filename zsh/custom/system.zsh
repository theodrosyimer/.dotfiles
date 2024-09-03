alias macosv=get_macos_version

function get_macos_version() {
  printf "${$(sw_vers -productVersion)%%.*}"
}

# function pls() {
# 	lsof -nPi | rg -i $@
# }
