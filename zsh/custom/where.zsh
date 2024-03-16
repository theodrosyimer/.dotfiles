function wherep() {
  input=$1

  if [[ -z "$input" ]]; then
    echo 'Enter a search' && return 1
  fi

  if [[ -n "$input" ]]; then
    where_resp_arr=(${(@s: :)$(type -a _z)})
    check_errs "$?" "${where_resp_arr}"

    if [[ "$?" -eq "0" ]] && [[ ! "${where_resp_arr[1]}" == "$input: shell built-in command" ]]; then
      for path in "${where_resp_arr[@]}"
        do
          # echo "$(readlink $path)"
          echo "$path:A"
        done
      return 0
    fi

    # if [[ "$?" -eq "0" ]] && [[ "${where_resp_arr[1]}" == "$input: shell built-in command" ]]; then
    #   where_path="${where_resp_arr[2]}"
    #   # echo "$(readlink $where_path)" && return 0
    #   echo "$where_path:A" && return 0
    # fi
  fi
}

function whereo() {
  input=$1
  input_path=$(wherep $input)
  input_path_array=(${(@f)input_path})

  if [[ "$?" -eq "1" ]]; then
    printf "%b\n" "$input_path"
    return 1
  fi

  dir="$(basename $input_path_array[1])"
  open -R "$dir"
}
