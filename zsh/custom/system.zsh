function get_macos_version() {
  printf "${$(sw_vers -productVersion)%%.*}"
}
