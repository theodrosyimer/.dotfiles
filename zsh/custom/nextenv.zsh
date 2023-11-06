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

function add_env() {
    local input="$1"
    local target=$2

    echo $input
    if [[ -z "$input" ]]; then
        echo "No input given!"
        return 1
    fi

    if ! [[ -s "$input" ]]; then
        echo "File is empty!"
        return 1
    fi

    if [[ -n "$input" ]] && [[ -n "$2" ]] && target=$2

    if [[ -n "$input" ]]; then
        echo "Target Environment: $target"

        # skip comments and empty inputs
        if [[ "$input" =~ ^#.* ]] || [[ "$input" =~ ^$ ]] && continue

        local name="$(echo "$input" | cut -d'=' -f1)"
        local value="$(echo "$input" | cut -d'=' -f2)"

        printf "%s" "$(printf "%s" "$value"  | tr -d '\n')" | vercel env add "$name" "$target"
    fi

    if [ -p /dev/stdin ]; then
        echo "Data was piped to this script!"

        local name="$(echo "$input" | cut -d'=' -f1)"
        local value="$(echo "$input" | cut -d'=' -f2)"
        echo "$value" | vercel env add "$name" "$2"
    else
        echo "Nothing done!"
    fi
}

function envadd(){
    # You can add or remove filenames to search for here
    # by adding or removing items from the array:
    #       local env_filenames=(.env .env.development .env.local .env.local.development .env.production .env.local.production .env.test .env.local.test)
    local env_files=(.env .env.development .env.local .env.local.development .env.production .env.local.production .env.test .env.local.test)
    local target="${2:-development}"

    for env_file in "${env_files[@]}"
        do
            [[ -s "$env_file" ]] && [[ -f "$env_file" ]] && input_file="$env_file"
        done

    cat ${1:-$input_file} | parallel --shuf -j+0 "$(where add_env);add_env {}" "$target"
}

function envdel() {
    local target=development

    if [[ -z "$1" ]]; then
        echo "No input given!"

        local answer
        vared -p 'Do you want to remove all environment variables? (y|n): ' -c answer

        case "${answer}" in
        y | Y)
            printf "Yes\n"
            local variables="$(vercel env ls | awk '{{if(NR>2) { print $1}}}')"

            local array=(${(@f)variables})

            # for variable in "${array[@]}"
            #     do
            #         # echo $variable
            #         vercel env rm "$variable" "$target" --yes
            #     done
            print -l $array | parallel --shuf -j+0 vercel env rm {} "$target" --yes
            return 0
            ;;

        n | N)
            printf "No\n"
            return 1
            ;;

        $'\n') # no answer
            printf "Yes\n"
            return 0
            ;;

        *) # This is the default
            printf "${answer}"
            return 1
            ;;
        esac
        unset answer # important
    fi

    # if [[ -n "$1" ]] && [[ -n "$2" ]]; then
    #     target=$2
    # fi
}
