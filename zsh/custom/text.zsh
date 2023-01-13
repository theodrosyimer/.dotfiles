function contains() {
  local string="$1"
  local regex="$2"

	local flag_help flag_sensitive
	local output_path=("${PWD}\/my-file.txt") # sets a default path
	local usage=(
	"contains [ -h | --help ]"
	"contains [ - | -- ] [ -o | --output <path/to/file> ]"
	)

	zmodload zsh/zutil
	zparseopts -D -F -K -- \
		{h,-help}=flag_help \
		{s,-sensitive}=flag_sensitive \
		{o,-output}:=output_path || return 1

	[[ -n "$flag_help" ]] && { print -l $usage && return; }

	if [[ -n "$flag_sensitive" ]]; then
		[[ "$string" =~ "$regex" ]] && return 0 || return 1
	else
		[[ "$string:l" =~ "$regex:l" ]] && return 0 || return 1
	fi
}

function trim() {
local flag_write flag_help
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

[[ -n "$flag_help" ]] && { print -l $usage && return; }

if [[ -n "$flag_write" ]]; then
	local input_array=(${(@)@})

	for input in "${input_array[@]}"
			do
				local result="$(echo -e "$input" | tr -d '\\n' | tr -d '\n' | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g')"
				echo -e "$result" >>"$output_path[-1]"
			done
	return
fi

if [[ -z "$flag_write" ]]; then
	local input_array=(${(@)@})

	for input in "${input_array[@]}"
			do
				local result_formatted="$(echo -e "$input" | tr -d '\\n' | tr -d '\n' | sed -e 's/^ *//g' -e 's/ *$//g' -e 's/_/-/g')" && echo -e $result_formatted
			done
	return
fi
}

function spaced_by() {
  local string=$1
  local character="${2:-\-}"
  echo -e "$(echo -e "$string" | tr -s ' ' "$character")"
}


function slugify() {
  local input_lowercased="$(trim ${@:l})"
  spaced_by "$input_lowercased"
}
