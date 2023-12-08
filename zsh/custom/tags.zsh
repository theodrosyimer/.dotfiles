function tags_get_all_user_tags() {
	cd ~ &&
		'tag' -tgf \* | 'rg' '^    ' | 'cut' -c5- | 'sort' -u | 'rg' -N --no-column '^(:1:    )(.+)' -r $1 '$2'
}

function tags_write_to_file() {
	local default_path="$HOME/.my_tags"
	local file_path=${1:-${default_path}}
	tags_get_all_user_tags >$file_path
	la $file_path
}

function tags_show() {
	cat $TAG_LIST
}

function tags_get_total_count() {
	tags_show | wc -l
}

alias tags=tags_show
alias tagsc=tags_get_total_count
alias tagsw=tags_write_to_file
