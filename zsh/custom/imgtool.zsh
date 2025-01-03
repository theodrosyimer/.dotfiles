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

	mogrify -path $output -filter Triangle -define filter:support=2 -thumbnail "$output_width" -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -define avif:speed=5 -interlace none -colorspace sRGB $1

	# [[ ! -d "$output_path[-1]" ]] && mkdir -p "$output_path[-1]"

	# if [[ -n "$input_path" ]] && [[ -n "$output_width" ]]; then
	# 	[[ ! -d "$output_path[-1]" ]] && mkdir -p "$output_path[-1]"
	# 	echo 'yesss'
	# 	mogrify -path "$output_path[-1]" -filter Triangle -define filter:support=2 -thumbnail "$output_width" -unsharp 0.25x0.25+8+0.065 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB -sampling-factor 4:2:0 -strip "$input_path"
	# else
	# 	echo -e '\nYou need to provide an image as an input and a width.\n' && print -l $usage && return
	# fi
}

function to_avif() {
  AVIF_SPEED=5
  convert -quality 50 -define avif:speed=$AVIF_SPEED "$1" "${1:-"${2}":h}.avif"
}

function img_convert_to() {
	# local extensions=("${1:-"jpg"}")
	local extensions=(jpg jpeg png webp avif)
	local output_path="${1:-"$(pwd)/images-converted"}"
  local imagesPath="$(fd -e jpg -e png -e avif -e jpeg -e webp -d 1)"
	local images=(${(@f)${imagesPath}})

  # echo "$imagesPath"
  echo "$images"

  if [[ ! -d "originals" ]]; then
    mkdir -p originals &&
    for image in $images; do
      cp $image ./originals
    done
  fi

  [[ $? -eq "0" ]] && printf "\n%s\n" "Original images copied to originals directory" || printf "\n%s\n" "Original images not copied to originals directory. Program terminated." || return 1

	for extension in "${extensions[@]}"; do
		[[ ! -d "$output_path/$extension" ]] && mkdir -p "$output_path/$extension"
	done

	time parallel --shuf --eta -j+0 convert -resize {3} -quality {2} {1} $output_path/{4}/{1.}_w{3}_q{2}.{4} ::: ${images[@]} ::: 80 90 100 ::: 50% 25% 10% ::: ${extensions[@]}

	# time parallel --shuf --eta -j+0 mogrify -write $output_path/{4}/{1.}_{3}_q{2}.{4} -quality {2} -filter Triangle -define filter:support=2 -thumbnail {3} -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -define avif:speed=5 -interlace none -colorspace sRGB {1} ::: ${images[@]} ::: 80 90 100 ::: 50% 25% 10% ::: ${extensions[@]}
}

function from_webp() {
	# local extension="${1:-"jpg"}"
	local extensions=(jpg jpeg png)
	local output_path="${2:-"$(pwd)/images-converted"}"
	local images=(${(@f)$(fd -e webp -d 1)})
  # echo "$(pwd)"/$images
  echo $images
	for extension in "${extensions[@]}"; do
		[[ ! -d "$output_path/$extension" ]] && mkdir -p "$output_path/$extension"
	done

	# for photo in "(${(@f)$(fd -e webp -d 1)})"; do
	# 	dwebp $photo -o ${photo%.*}.jpg;
	# done

  time parallel --shuf --eta -j+0 'dwebp "$(pwd)"/{1} -o "$output_path"/{2}/{1.}.{2}' ::: ${images[@]} ::: ${extensions[@]}
}

function to_webp() {
	if [[ -d "$1" ]]; then
			# local images="($1/*.{jpg,jpeg,png})"
			local images=(${(@f)$(fd -e jpg -e png -e jpeg --base-directory "$1" -d 1)})
	fi

	if (($#@ > 1)); then
			local images=(${(@f)@})
			local list="${images[@]}"
	fi

  time parallel --shuf --eta -j+0 cwebp -q 80 {1} -o {1.}.webp ::: ${images[@]}
}
