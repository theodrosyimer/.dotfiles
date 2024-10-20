function notify() {
  local current_app_name=$(osascript -e 'tell application "System Events" to return name of first process whose frontmost is true')
  local message="${1:-"Done!"}"
  local title="${2:-"$current_app_name"}"

  osascript -e "display notification \"$message\" with title \"$title\""
}
