function case_example {

  # read -rs -k 1 answer # bash
  # local answer='hello'
  local answer
  vared -p 'Do you like chocolate? (y|n): ' -c answer

  case "${answer}" in
  y | Y)
    printf "Yes\n"
    return 0
    ;;

  n | N)
    printf "No\n"
    return 0
    ;;

  $'\n') # no answer
    printf "Yes\n"
    return 0
    ;;

  *) # This is the default
    printf "${answer}"
    return 1
    ;;
  esac
  unset answer

}
