function mka() {
  local inputs=($@)
  echo $1
  echo ${inputs}
  echo $2 > files
   echo $1 | parallel 'mkdir -p {1} && cd {1} && touch {2}.js' ::: - ::: files
}
