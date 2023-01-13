function brew_dump() {
	local prev_dir="$PWD"
	local output_path="${1:-$DOTFILES:-.}"

	# because functions are run in the existing shell
	# (scripts are run in a subshell)
	# when using `cd` in a function...
	cd "$output_path" &&
		brew bundle dump --force --describe &&
		cat Brewfile &&
		# ... i need to return back to previous $PWD
		# if i don't want to change the user working directory
		# or i need to use a script instead of a function...
		cd "$prev_dir"
}
