# inspiration:[scripts - How to round decimals using bc in bash? - Ask Ubuntu](https://askubuntu.com/a/626782)
function round() {
  local input=$1
  local scale=${2:-2}

  echo $(printf %.${scale}f $(($input)))
}

# inspiration: [scripts - How to round decimals using bc in bash? - Ask Ubuntu](https://askubuntu.com/a/179949)
function round_bash() {
  local input=$1
  local scale=${2:-2}

  echo $(printf %.${scale}f $(echo "scale=$scale;(((10^$scale)*$input)+0.5)/(10^$scale)" | bc))
}

# Faster using `awk`
#inspiration: [scripts - How to round decimals using bc in bash? - Ask Ubuntu](https://askubuntu.com/a/1179424)
function round_awk() {
  local input=$1
  local scale=${2:-2}

  awk "BEGIN{printf(\"%.${scale}f\n\",$input)}"
}
