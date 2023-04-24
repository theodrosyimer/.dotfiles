# source: [Efficient Image Resizing With ImageMagick — Smashing Magazine](https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/#image-optimization)

function optimg() {
	local flag_help input_path output_width
	local output_path=("${PWD}/images-optimized")
	local usage=(
		"magikopt [ -h | --help ]"
		"magikopt [ -w | --width <size> ] [ -o | --output <path/to/file> ] [ -i | --input <path/to/file>... ]"
	)

	zmodload zsh/zutil
	zparseopts -D -F -K -- \
		{h,-help}=flag_help \
		{i,-input}=input_path \
		{w,-width}=output_width \
		{o,-output}:=output_path ||
		return 1

	[[ -n "$flag_help" ]] && { print -l $usage && return; }

	local output=${3:-"$PWD/images-optimized"}

	[[ ! -d $output ]] && mkdir -p $output

	mogrify -path $output -filter Triangle -define filter:support=2 -thumbnail $2 -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB $1

	# [[ ! -d "$output_path[-1]" ]] && mkdir -p "$output_path[-1]"

	# if [[ -n "$input_path" ]] && [[ -n "$output_width" ]]; then
	# 	[[ ! -d "$output_path[-1]" ]] && mkdir -p "$output_path[-1]"
	# 	echo 'yesss'
	# 	mogrify -path "$output_path[-1]" -filter Triangle -define filter:support=2 -thumbnail "$output_width" -unsharp 0.25x0.25+8+0.065 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB -sampling-factor 4:2:0 -strip "$input_path"
	# else
	# 	echo -e '\nYou need to provide an image as an input and a width.\n' && print -l $usage && return
	# fi
}

function from_webp() {
	local extension="${1:-"jpg"}"
	local webpFiles="$(fd -e webp)"

	local files=(${(@f)webpFiles})

	for file in "${files[@]}"
  do
    dwebp "$file" -o "$file:r.$extension"
  done
}

function to_webp() {

	if [[ -d "$1" ]]; then
			local list="$1/*"
	fi

	if (($#@ > 1)); then
			local files=(${(@f)@})
			local list="${files[@]}"
	fi

	for file in $list
  do
    cwebp "$file" -o "${file%.*}.webp"
    # cwebp -q 50 "$file" -o "${file%.*}.webp"
  done
}


function hil() {
	(($#@ > 1)) && echo yes || no
}
