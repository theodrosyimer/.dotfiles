# function enva() {
#     local target=development

#     if [[ -z "$1" ]]; then
#         echo "No input given!"
#         return 1
#     fi

#     if [[ -n "$1" ]] && [[ -n "$2" ]]; then
#         target=$2
#     fi

#     if [[ -f "$1" ]]; then
#         echo "Input is a file"

#         echo "Target Environment: $target"

#         while IFS= read -r line; do
#             # skip comments and empty lines
#             if [[ "$line" =~ ^#.* ]] || [[ "$line" =~ ^$ ]]; then
#                 continue
#             fi
#             local name="$(echo "$line" | cut -d'=' -f1)"
#             local value="$(echo "$line" | cut -d'=' -f2)"
#             # printf "%s" "$name" "$value"
#             printf "%s" "$(printf "%s" "$value"  | tr -d '\n')" | vercel env add "$name" "$target"
#         done < "$1"
#     else
#         if [ -p /dev/stdin ]; then
#         echo "Data was piped to this script!"

#         while IFS= read -r line; do
#             local name="$(echo "$line" | cut -d'=' -f1)"
#             local value="$(echo "$line" | cut -d'=' -f2)"
#             echo "$value" | vercel env add "$name" "$2"
#         done <<< "$1"
#         else
#         echo "No input given!"
#         fi
#     fi
# }

# works with the script in .dotfiles/bin/envadd, go check it
function add_env() {
    local input="$1"
    local target=$2

    if [[ -z "$input" ]]; then
        echo "No input given!"
        return 1
    fi

    if ! [[ -s "$input" ]]; then
        echo "File is empty!"
        return 1
    fi

    if [[ -n "$input" ]] && [[ -n "$2" ]] && target=$2

    if [[ -s "$input" ]]; then
        echo "Target Environment: $target"

        # skip comments and empty inputs
        if [[ "$input" =~ ^#.* ]] || [[ "$input" =~ ^$ ]] && continue

        local name="$(echo "$input" | cut -d'=' -f1)"
        local value="$(echo "$input" | cut -d'=' -f2)"

        printf "%s" "$(printf "%s" "$value"  | tr -d '\n\r')" | vercel env add "$name" "$target"
    fi

    if [ -p /dev/stdin ]; then
        echo "Data was piped to this script!"

        local name="$(echo "$input" | cut -d'=' -f1)"
        local value="$(echo "$input" | cut -d'=' -f2)"
        echo "$value" | vercel env add "$name" "$2"
    else
        echo "No input given!"
    fi
}
