function income() {
  SOCIAL_TAXES_PERCENTAGE=0.2168423077 # in France
  INCOME_TAXES_PERCENTAGE=0.041 # in France

  local flag_help flag_yearly flag_monthly flag_after_tax flag_from_net
  local output_path=("${PWD}\/my-file.txt") # sets a default path
  local usage=(
  "netinc [ -h | --help ]"
  "netinc [ -y | --yearly ] - from gross income and before taxes"
  "netinc [ -m | --monthly ] - from gross income and before taxes"
  "netinc [ -ay | --after-tax-yearly ] - from gross income"
  "netinc [ -am | --after-tax-monthly ] - from gross income"
  # TODO: add after-tax from net income
  # "netinc [ -ny | --from-net-yearly ] - before taxes"
  # "netinc [ -nm | --from-net-monthly ] - before taxes"
  # ## "netinc [ -any | --after-tax-yearly-from-net ]"
  # "netinc [ -anm | --after-tax-monthly-from-net ]"
  # "netinc [ -n | --from-net ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {y,-yearly}=flag_yearly \
    {m,-monthly}=flag_monthly \
    {a,-after-tax}=flag_after_tax \
    {n,-from-net}=flag_from_net \
    {o,-output}:=output_path || return 1

  [[ -n "$flag_help" ]] && { print -l $usage && return; }

  if [[ -n "$flag_after_tax" ]]; then
    if [[ -n "$flag_yearly" ]]; then
      result="(( $1 / 12 * ( 1 - $SOCIAL_TAXES_PERCENTAGE ) ))"
      # printf "%.2f\n" $result
      printf "%.2f\n" $(( $result - ( $result * $INCOME_TAXES_PERCENTAGE ) )) &&
      return 0
    fi

    if [[ -n "$flag_monthly" ]]; then
      result="$(( $1 * ( 1 - $SOCIAL_TAXES_PERCENTAGE ) ))"
      # printf "%.2f\n" $result
      printf "%.2f\n" $(( $result - ( $result * $INCOME_TAXES_PERCENTAGE ) )) &&
      return 0
    fi
  fi

  if [[ -n "$flag_yearly" ]]; then
    printf "%.2f\n" $(( $1 / 12 * ( 1 - $SOCIAL_TAXES_PERCENTAGE) )) &&
    return 0
  fi

  if [[ -n "$flag_monthly" ]]; then
    printf "%.2f\n" $(( $1 * ( 1 - $SOCIAL_TAXES_PERCENTAGE ) )) &&
    return 0
  fi
}
