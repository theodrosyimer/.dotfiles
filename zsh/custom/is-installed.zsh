function is_installed() {
	local error_message=(
		"$_yellow\nI require $_cyan${1}$_yellow but it is not installed.$_reset\n"
		)
	local infos_message=(${@[@]:2})

	# more portable
	command -v "${1}" >/dev/null 2>&1 || { \
	printf >&2 "%b\n" "$error_message$_reset" && \
	printf >&2 "%b\n" $infos_message && \
	return 1; }

	# zsh
	# command -v "${1}" >/dev/null 2>&1 || { \
	# print >&2 -lP "$error_message" && \
	# print >&2 -lP $infos_message && \
	# return 1; }

	# bash and zsh
	# TODO: make it work with an array
	# command -v "${1}" >/dev/null 2>&1 || { \
	# echo "$error_message" && \
	# echo >&2 $infos_message && \
	# return 1; }
}
