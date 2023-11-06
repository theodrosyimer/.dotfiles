function _dev() {
	# dir_list=(
#   "~/Code/projects"
#   "~/"
#   "~/Code"
#   "~/Code/courses"
#   "~/Code/_templates"
#   "~/Code/_templates/dev"
#   "~/Code/_templates/dev/ts"
#   "~/Code/_templates/dev/js"
#   "~/Code/refs"
#   "~/Code/refs/js/sandbox"
#   "~/Design"
#   )

dir_list="$(find $DOTFILES ~/Code/projects ~/ ~/Code ~/Code/courses ~/Code/_templates ~/Code/_templates/dev ~/Code/_templates/dev/ts ~/Code/_templates/dev/js ~/Code/refs ~/Code/refs/js/sandbox ~/Design -mindepth 1 -maxdepth 1 -type d))"

fm "${dir_list}"
}

zle -N _dev
bindkey -v
bindkey "^[f" _dev
