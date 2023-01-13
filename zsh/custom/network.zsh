function local_ip() {
  local ip_from_ethernet="$(ipconfig getifaddr en0)"
  local ip_from_wifi="$(ipconfig getifaddr en1)"

  if [[ -n $ip_from_ethernet ]]; then
    echo -e "\nfrom ETHERNET connection: "
    echo -e "$ip_from_ethernet\n"
    trim "$ip_from_ethernet" | pbcopy
    echo "copied to your clipboard!"
  else
    echo -e "\nfrom WIFI connection: "
    echo -e "$ip_from_wifi\n"
    trim "$ip_from_wifi" | pbcopy
    echo "copied to your clipboard!"
  fi
}

function list_network_hardwares() {
  networksetup -listallhardwareports
}
