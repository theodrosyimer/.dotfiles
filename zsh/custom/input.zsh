function isNotEmpty() {
	if [[ "$#1" -eq '0' ]] || [[ -z "$1" ]]; then
	 	return 1
	else
		return 0
	fi
}

function isEmpty() {
	if [[ "$#1" -eq '0' ]] || [[ -z "$1" ]]; then
	 	return 0
	else
		return 1
	fi
}
