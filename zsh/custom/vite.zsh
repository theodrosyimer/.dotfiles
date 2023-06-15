function vites() {
local dir_path=${1:-${PWD}}
local version=${2:-latest}
local project_name_default='my-project'

local templates=(vanilla vanilla-ts vue vue-ts react react-ts preact preact-ts lit lit-ts svelte svelte-ts)
local name

vared -p 'Name your project (default: my-project): ' -c name

# if no input (user type enter without answering)
# `name` is not an empty string but an empty line
if [[ name =~ ^$ ]]; then
  local project_name="$project_name_default"
 else
  local project_name="$name"
fi

echo
echo -e 'Type a number to select a template,\nType enter to validate (ctrl+C to cancel):\n'

select template in ${(@)templates}
  do
    echo "Your selection: $template"
  break
  done

## NPM ##

# cd "$dir_path" &&
# npm create "vite@$version" "$project_name" -- --template "${template}" &&

# echo -e "Running:\n"
# echo "  cd $project_name"
# echo -e "  npm install"
# echo -e "  npm run dev\n"

# cd "$project_name" &&
#   code -gn . index.html &&
#   npm install &&
#   npm run dev


## PNPM ##

cd "$dir_path" &&
pnpm create vite "$project_name" -- --template "${template}" &&

echo -e "Running:\n"
echo "  cd $project_name"
echo -e "  npm install"
echo -e "  npm run dev\n"

cd "$project_name" &&
  code -gn . &&
  pnpm install &&
  pnpm run dev
}
