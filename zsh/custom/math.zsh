# inspiration: [Shell Script To Check For a Valid Floating-Point Value - GeeksforGeeks](https://www.geeksforgeeks.org/shell-script-to-check-for-a-valid-floating-point-value/)

function is_int() {

  # local num
  # # User Input...
  # vared -p "Enter the number : " -c num

  # or...
  local num=$1

  # Check for a number
  [[ "$num" =~ '^[+-]?[0-9]+$' ]] || return 1
}

function is_float() {

  # local num
  # # User Input...
  # vared -p "Enter the number : " -c num

  # or...
  local num=$1

  # Check for a floating number
  [[ "$num" =~ '^[+-]?[0-9]*\.[0-9]+$' ]] || return 1
}

function is_nan() {

  # local num
  # # User Input...
  # vared -p "Enter the number : " -c num

  # or...
  local num=$1

  # oneliner using functions above
  is_int $1 || is_float $1 && return 1

  # or check for a number and float number
  if [[ $num =~ '^[+-]?[0-9]+$' ]] || [[ $num =~ '^[+-]?[0-9]*\.?[0-9]+$' ]] && return 1
}

function is_number() {

  # local num
  # # User Input...
  # vared -p "Enter the number : " -c num

  # or...
  local num=$1

  # oneliner using functions above
  is_int $1 || is_float $1 && return 0

  # or check for a number and float number
  # if [[ $num =~ '^[+-]?[0-9]+$' ]] || [[ $num =~ '^[+-]?[0-9]*\.?[0-9]+$' ]] && return 0
}

# source: https://stackoverflow.com/a/13407864/9103915
function get_decimal_from_float() {
  local input=$1
  local result=$(echo $input | sed -E 's/^[+-]?([0-9]*)(\.)([0-9]+)$/\3/')

  echo $result | bc -l
}

# source: https://stackoverflow.com/a/13407864/9103915
function get_integer_from_float() {
  local input=$1
  local result=$(echo $input | sed -E 's/^[+-]?([0-9]*)(\.)([0-9]+)$/\1/')

  echo $result | bc -l
}

