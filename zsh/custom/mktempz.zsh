#!/usr/bin/env zsh

####
## A nice and shorter way to achieve the same result, works ONLY in zsh (?)
## See [zsh: 14 Expansion](http://zsh.sourceforge.net/Doc/Release/Expansion.html#Process-Substitution)
## > The temporary file created by the process substitution will be deleted when the function exits.
####

function mktempz(){
  local input="$@"
  local ext=md

  # check if there are any arguments otherwise use the clipboard
  if [[ -n $@ ]]; then
    input="$@"
  else
    input=$(pbpaste)
  fi

  # here is the important part
  () {
    echo $input > $1.$ext
    # i use iThoughts X as an example
    open -a "Visual Studio Code" $1.$ext
  } =(print $input)

}


