function local_ip() {
  local ip_from_ethernet
  local ip_from_wifi

  # define the command to get the local ip
  case "$OSTYPE" in
    darwin*)  ip_from_ethernet="$(ipconfig getifaddr en0)"; \
              ip_from_wifi="$(ipconfig getifaddr en1)" ;;
    cygwin*)  ip_from_ethernet="$(ipconfig.exe | grep -im1 'IPv4 Address' | cut -d ':' -f2)"; \
              ip_from_wifi= ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && ip_from_ethernet="$(ifconfig en0 | grep inet | grep -v inet6 | cut -d" " -f2)"; \
              ip_from_wifi="$(ifconfig en1 | grep inet | grep -v inet6 | cut -d" " -f2)" || {
              #   [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1; }
              echo 'wsl?'
              #   ip_from_ethernet="$(ipconfig.exe | grep -im1 'IPv4 Address' | cut -d ':' -f2)"
              #   ip_from_wifi=
              }
              ;;
    *)        echo "Platform $OSTYPE not supported"
              return 1
              ;;
  esac

  if [[ -n $ip_from_ethernet ]]; then
    printf "%b\n" "\nLocal IP (ETHERNET): $_cyan$ip_from_ethernet$_reset\n"
    trim "$ip_from_ethernet" | pbcopy
    echo "$_grey""Copied to clipboard!$_reset"
  else
    printf "%b\n" "\nLocal IP (WIFI): "
    printf "%b\n" "$ip_from_wifi\n"
    trim "$ip_from_wifi" | pbcopy
    echo "Copied to clipboard!"
  fi
}

function get_network_hardware_list() {
  networksetup -listallhardwareports
}

function open_local_ip_at() {
  local local_url

  [[ -z "$1" ]] && { printf "%b\n" "\n$_yellow""Please provide a port number$_reset"; return 1; }

  [[ "$1" -lt 1 || "$1" -gt 65535 ]] && { \
    printf "%b\n" "\n$_yellow""Port number must be between 1 and 65535$_reset"; return 1; }

  local_ip 1 > /dev/null; local_url="http://$(pbpaste):$1" && \
    open "$local_url" && \
    printf "%s"  "$local_url" | pbcopy && \
    printf "%b\n" "\n$_green""Copied to your clipboard!$_reset"
}

alias lip='local_ip'
alias nhls='networksetup -listallhardwareports'
alias olip='open_local_ip_at'
