function modbin() {
  local my_path=${1:-$HOME/bin/*.*}

  chmod +x "$my_path"
  echo 'Done'
}

function modjs() {
  local my_path=${1:-$HOME/.js/*}

  chmod +x "$my_path"
  echo 'Done'
}

function chmodall() {
  local who=${1:-}
  local operation=
  local dir=${2:-.}
  local usage=(
    "chmodall [ | a | u | g | o ] [ <path/to/file> ]"
    "chmodall [ ug ] [ <path/to/file> ]"
    "chmodall [ uo ] [ <path/to/file> ]"
    "chmodall [ go ] [ <path/to/file> ]\n"
    "[ =all | a=all | u=user | g=group | o=others ]"
  )

  # if [[ -z $who ]] || [[ $who == "u" ]] || [[ $who == "g" ]] || [[ $who == "o" ]] || [[ $who == "a" ]]; then
  #   'fd' --base-directory "$dir" -x chmod $who+x {}
  # else
  #   print -l $usage
  # fi

# case $who in
#   u)
#     'fd' --base-directory "$dir" -x chmod u+x {}
#   ;;
#   g)
#     'fd' --base-directory "$dir" -x chmod g+x {}
#   ;;
#   o)
#     'fd' --base-directory "$dir" -x chmod o+x {}
#   ;;
#   a)
#     'fd' --base-directory "$dir" -x chmod a+x {}
#   ;;
#   *)
#     print -l $usage
#   ;;
# esac

}
