## inspiration: [shell script - Get total duration of video files in a directory - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/170961/get-total-duration-of-video-files-in-a-directory)

function gvd() {
  local dir_path=${1:-${PWD}}
  local depth=${2:-2}
  local ext=mp4
  local duration="$(fd -e $ext --base-directory "$dir_path" -d "$depth" -x ffprobe -v quiet -of csv=p=0 -show_entries format=duration | paste -sd+ - | bc)"

  if [[ -z $duration ]]; then
    echo "No video (*.$ext) found in '$dir_path'"
    return 1
  fi


  if (($duration >= 3600)); then
    local gt_1hr_result="$(($duration / 3600))"
    if is_float $gt_1hr_result; then
      # echo "more than 1 hour and is a float-point number"
      integer_from_float=$(get_integer_from_float $gt_1hr_result)
      decimal_from_float=$(get_decimal_from_float $gt_1hr_result)
      minutes_from_decimal=$(($decimal_from_float * 60))
      first_two_digit=${minutes_from_decimal:0:2}

      echo $integer_from_float"h"$first_two_digit"min" && return 0
    elif is_int $gt_1hr_result; then
      # echo "more than 1 hour and is an integer"
      echo $(printf %.2f $(echo $gt_1hr_result | bc -l)) && return 0
    fi
  fi


  if (($duration < 3600)); then
    local lt_1hr_result="$(($duration / 60))"
    if is_float $lt_1hr_result; then
      # echo "less than 1 hour and is a float-point number"
      integer_from_float=$(get_integer_from_float $lt_1hr_result)
      decimal_from_float=$(get_decimal_from_float $lt_1hr_result)
      seconds_from_decimal_part=$(($decimal_from_float * 60))
      first_two_digit=${seconds_from_decimal_part:0:2}

      echo $integer_from_float"min"$first_two_digit"sec" && return 0
    elif is_int $lt_1hr_result; then
      # echo "less than 1 hour and is an integer"
      echo $(printf %.2f $(echo $lt_1hr_result | bc -l)) && return 0
    fi
  fi
}

# Old version
function gvd_OLD() {
  local dir_path=${1:-${PWD}}
  local depth=${2:-2}
  local ext=mp4
  local duration="$(fd -e $ext --base-directory "$dir_path" -d $depth -x ffprobe -v quiet -of csv=p=0 -show_entries format=duration | paste -sd+ - | bc)"

  if [[ -z $duration ]]; then
    echo "No video (*.$ext) found in '$dir_path'"
    return 1
  fi

  (($duration > 3600)) &&
    echo $(printf %.2f $(echo $(($duration / 3600)) | bc -l)) ||
    echo $(printf %.2f $(echo $(($duration / 60)) | bc -l))
}

# ≈4.5x slower than `gvd_OLD`!!
function gvd_slow() {
  local dir_path=${1:-${PWD}}
  local depth=${2:-2}
  local ext=mp4
  local duration=$(find "$dir_path" -maxdepth $depth -iname "*.$ext" -exec ffprobe -v quiet -of csv=p=0 -show_entries format=duration {} \; | paste -sd+ - | bc)

  if [[ -z $duration ]]; then
    echo "No video (*.$ext) found in '$dir_path'"
    return 1
  fi

  (($duration > 3600)) &&
    echo $(printf %.2f $(echo $(($duration / 3600)) | bc -l)) ||
    echo $(printf %.2f $(echo $(($duration / 60)) | bc -l))
}

function gvd_compare() {
  local dir_path=${1:-${PWD}}
  local depth=${2:-2}

  time (gvd $dir_path $depth)
  time (gvd_OLD $dir_path $depth)
  time (gvd_slow $dir_path $depth)
}
