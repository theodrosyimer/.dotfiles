function isInputNotEmpty() {
	if isInputEmpty && 1 || 0
}

function isInputEmpty() {
	if [[ "$#1" -eq '0' ]] || [[ -z "$1" ]]; then
	 	return 0
	else
		return 1
	fi
}
