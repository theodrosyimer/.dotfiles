# source: https://stackoverflow.com/a/13407864/9103915
function get_integer_from_float() {
  local input=$1
  local result=$(echo $input | sed -E 's/^[+-]?([0-9]*)(\.)([0-9]+)$/\1/')

  echo $result | bc -l
}
