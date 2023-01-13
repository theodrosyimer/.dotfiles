function chrome_get_front_window_url() {
  echo $(osascript -e 'tell application "Google Chrome" to return URL of active tab of front window')
}

function chrome_get_front_window_title() {
  echo $(osascript -e 'tell application "Google Chrome" to return title of active tab of front window') | sed -E 's/^(\([0-9]*\) )(.+)$/\2/g'
}

function chrome_open_tabs_in_new_window() {
	local url=(${(@)@})

	local chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

	if [[ ! -x $chrome ]]; then
		echo '[ERROR]: chrome is not installed or not found'
		return 1
	fi

	chrome --new-window &&

	for u in "${url[@]}"; do
		echo $u
		open $u
	done
}

function chrome_get_all_tabs_from_front_window() {
  local to_json_script="browser='Google Chrome'
  var tabsCollection = []
  var getAllTabs = () => {
  var tabs = Application(browser).windows[0].tabs()
  tabs.forEach(t => {
    let regex = /^(\(\d+\))\s/g
    let title = t().title().replace(regex, '')
    let url = t().url()
    tabsCollection.push({ title, url })
    })
  return JSON.stringify(tabsCollection)
  }
  getAllTabs()"

  local to_csv_script="browser='Google Chrome'
  var tabsString = ['title,url', '\n']
  var getAllTabs = () => {
  var tabs = Application(browser).windows[0].tabs()
  tabs.forEach(t => {
    let regex = /^(\(\d+\))\s/g
    let title = t().title().replace(regex, '')
    let url = t().url()
    let row = '\"' + title + '\"' + ',' + url
    tabsString.push(row,'\n')
    })
  return tabsString.join('')
  }
  getAllTabs()"

  local to_md_script="browser='Google Chrome'
  var tabsString = ['# Links List in Markdown', '\n', '\n']
  var lineNumber = 0
  var getAllTabs = () => {
  var tabs = Application(browser).windows[0].tabs()
  tabs.forEach(t => {
    let regex = /^(\(\d+\))\s/g
    let title = t().title().replace(regex, '')
    let url = t().url()
    let row = ++lineNumber + '. ' + '[' + title + ']' + '(' + url + ')'
    tabsString.push(row,'\n')
    })
  return tabsString.join('')
  }
  getAllTabs()"

  local flag_help flag_pretty flag_json flag_csv flag_markdown
  local output_path=("${PWD}/urls") # sets a default path
  local usage=(
    "chrome_get_all_tabs_from_front_window [ -h | --help ]"
    "chrome_get_all_tabs_from_front_window [ -p | --pretty-print ] [ -o | --output <path/to/file> ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {c,-csv}=flag_csv \
    {j,-json}=flag_json \
    {md,-markdown}=flag_markdown \
    {p,-pretty-print}=flag_pretty \
    {o,-output}:=output_path || return 1

  [[ -n "$flag_help" ]] && { print -l $usage && return; }

  [[ -n "$flag_pretty" ]] && { echo "$tabs_json" | json && return; }

  [[ -n "$flag_csv" ]] && { \
    local tabs_csv="$(osascript -l JavaScript -e "$to_csv_script")" && \
      echo "$tabs_csv" >"$output_path[-1].csv" && \
      code "$output_path[-1].csv" && return; }

  [[ -n "$flag_json" ]] && { \
    local tabs_json="$(osascript -l JavaScript -e $to_json_script)" && \
      echo "$tabs_json" | json >"$output_path[-1].json" && \
      code "$output_path[-1].json" && return; }

  [[ -n "$flag_markdown" ]] && { \
    local tabs_md="$(osascript -l JavaScript -e $to_md_script)" && \
      echo "$tabs_md" >"$output_path[-1].md" && \
      code "$output_path[-1].md" && return; }

  [[ "$@" -eq "0" ]] && { \
    local tabs_json="$(osascript -l JavaScript -e $to_json_script)" && \
      echo "$tabs_json" && return; }

}

alias churl='chrome_get_front_window_url'
alias cht='chrome_get_front_window_title'
