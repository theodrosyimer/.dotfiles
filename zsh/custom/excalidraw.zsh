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

filename="$(slugify "$1")"

touch "$filename" && code "$filename"
}
