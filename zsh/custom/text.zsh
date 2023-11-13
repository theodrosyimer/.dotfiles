function contains() {
  local regex="$1"
  local string="$2"

	local flag_help
	local flag_sensitive
	local output_path=("${PWD}\/my-file.txt") # sets a default path
	local usage=(
	"contains [ -h | --help ]"
	"contains [ -s | --sensitive ] [ -o | --output <path/to/file> ]"
	)

	zmodload zsh/zutil
	zparseopts -D -F -K -- \
		{h,-help}=flag_help \
		{s,-sensitive}=flag_sensitive \
		{o,-output}:=output_path || return 1

	[[ -n "$flag_help" ]] && { print -l $usage && return 0; }

	if [[ -n "$flag_sensitive" ]]; then
		[[ "$string" =~ "$regex" ]] && return 0 || return 1
	else
		[[ "$string:l" =~ "$regex:l" ]] && return 0 || return 1
	fi
}

function trim() {
local flag_write
local flag_help
local output_path=("${PWD}/my-file.txt") # sets a default path
local usage=(
"trim [ -h | --help ]"
"trim [ -w | --write ] [ -o | --output <path/to/file> ]"
)

zmodload zsh/zutil
zparseopts -D -F -K -- \
	{h,-help}=flag_help \
	{w,-write}=flag_write \
	{o,-output}:=output_path || return 1

[[ -n "$flag_help" ]] && { print -l $usage && return 0; }

if [[ -n "$flag_write" ]]; then
	local input_array=(${(@)@})

	for input in "${input_array[@]}"
			do
				local result="$(echo -e "$input" | tr -d '\n\r' | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g')"
				echo -e "$result" >>"$output_path[-1]"
			done
	return 0
fi

if [[ -z "$flag_write" ]]; then
	local input_array=(${(@)@})

	for input in "${input_array[@]}"
			do
				local result_formatted="$(echo -e "$input" | tr -d '\n\r' | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g')" && echo -e $result_formatted
			done
	return 0
fi
}

function spaced_by() {
  local string=$1
  local character="${2:-\-}"
  echo -e "$(echo -e "$string" | tr -s ' ' "$character")"
}


function slugify() {
	local flag_help
	local flag_delimiter=()
	local output_path=("${PWD}\/my-file.txt") # sets a default path
	local usage=(
	"slugify [ -h | --help ]"
	"slugify [ - | -- ] [ -o | --output <path/to/file> ]"
	)

	zmodload zsh/zutil
	zparseopts -D -F -K -E -- \
		{h,-help}=flag_help \
		{d,-delimiter}:=flag_delimiter \
		{o,-output}:=output_path || return 1

	[[ -n "$flag_help" ]] && { print -l $usage && return 0; }

	if [[ -n "$flag_delimiter" ]]; then
  	local input_lowercased="$(trim ${@:l})"
		spaced_by "$input_lowercased" $flag_delimiter[-1]
		return 0
	fi

	local input_lowercased="$(trim ${@:l})"
	spaced_by "$input_lowercased"
}

# source: https://dirask.com/posts/Bash-JavaScript-encodeURIComponent-equivalent-DKo8xD
function create_utf8_code() {
	local code="$(echo -n "$1" | xxd -ps)"
	local length="${#code}"

	local i

	for (( i = 0; i < length; i += 2 ))
	do
		echo -n "%${code:$i:2}" | tr '[:lower:]' '[:upper:]'
	done
}

function encode_uri_component() {
	local text="${1}"
	local length="${#text}"

	local i char

	for (( i = 0; i < length; ++i ))
	do
		char="${text:$i:1}"
		[[ "$char" =~ [-_.!~*\'\(\)a-zA-Z0-9] ]] && echo -n "$char" || create_utf8_code "$char"
	done
}

# i added this very simple decode_uri_component function
function decode_uri_component() {
	local text="${1}"

  printf "%s" $(echo "$text" | xxd -r -ps)
}
