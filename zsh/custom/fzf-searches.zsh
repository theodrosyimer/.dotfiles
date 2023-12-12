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

dir_list="$(find $DOTFILES $CODE $CODE_PERSONAL $CODE_COURSES $CODE_WORK $CODE_REFS $CODE_TEMPLATES $CODE_TEMPLATES/dev $CODE_TEMPLATES/dev/ts $CODE_TEMPLATES/dev/js $JS_SANDBOX $CODE_COURSES $CODE_WORK  $HOME/Design $HOME -mindepth 1 -maxdepth 1 -type d)"

fm "${dir_list}" && return $?
}

zle -N _dev
bindkey -v
bindkey "^[f" _dev
