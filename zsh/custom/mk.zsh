function mk() {

  selected="$(cat dev-dirlist | fzf)"

  case $selected in
    1) echo 1
    ;;
    2|3) echo 2 or 3
    ;;
    4) echo 4
    ;;
    *) echo default
    ;;
  esac

}
