function excalidraw() {
	# template=(
#  "{"
#  "  \"type\": \"excalidraw\","
#  "  \"version\": 2,"
#  "  \"source\": \"https://excalidraw.com\","
#  "  \"elements\": [],"
#  "  \"appState\": {"
#  "  \"viewBackgroundColor\": \"#000\""
#  "  }"
# "}"
# )
# print -l $template > "$1.excalidraw.json" && code -n "$_.json"

input_trimmed="$(slugify "$1")"
filename="$input_trimmed.excalidraw.json"

touch "$filename" && code -r "$filename"

}

alias xcal='excalidraw'
