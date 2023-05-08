function fzf_experiments() {
	 list | fzf --bind 'ctrl-r:reload(list)' --header 'Press CTRL-R
       to reload'
}
