alias churl='chrome_get_front_window_url'
alias cht='chrome_get_front_window_title'
alias churls='chrome_get_all_urls_from_front_window'
alias chourls='chrome_open_urls_from_file'
alias chrurls='get_urls_from_file | chrome_open_urls_from_file'

# ! Only works for macos as it uses osascript to execute applescript
function chrome_get_front_window_url() {
  echo $(osascript -e 'tell application "Google Chrome" to return URL of active tab of front window')
}

# ! Only works for macos as it uses osascript to execute applescript
function chrome_get_front_window_title() {
  echo $(osascript -e 'tell application "Google Chrome" to return title of active tab of front window') | sed -E 's/^(\([0-9]*\) )(.+)$/\2/g'
}

# ! Only works for macos as it uses osascript to execute JXA (applescript alternative)
# ! Dependencies: json
function chrome_get_all_urls_from_front_window() {
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
  var tabsString = ['title,url']
  var getAllTabs = () => {
  var tabs = Application(browser).windows[0].tabs()
  tabs.forEach(t => {
    let regex = /^(\(\d+\))\s/g
    let title = t().title().replace(regex, '')
    let url = t().url()
    let row = '\"' + title + '\"' + ',' + url
    tabsString.push('\n', row)
    })
  return tabsString.join('')
  }
  getAllTabs()"

  local to_md_script="browser='Google Chrome'
  var tabsString = ['# Links List in Markdown', '\n']
  var lineNumber = 0
  var getAllTabs = () => {
  var tabs = Application(browser).windows[0].tabs()
  tabs.forEach(t => {
    let regex = /^(\(\d+\))\s/g
    let title = t().title().replace(regex, '')
    let url = t().url()
    let row = ++lineNumber + '. ' + '[' + title + ']' + '(' + url + ')'
    tabsString.push('\n', row)
    })
  return tabsString.join('')
  }
  getAllTabs()"

  local to_no_ext_script="browser='Google Chrome'
  var tabsString = []
  var lineNumber = 0
  var getAllTabs = () => {
  var tabs = Application(browser).windows[0].tabs()
  tabs.forEach((t, i) => {
    let regex = /^(\(\d+\))\s/g
    // let title = t().title().replace(regex, '')
    let url = t().url()
    if (i === 0) {
      tabsString.push(url)
    }
    // let row = ++lineNumber + '. ' + '[' + title + ']' + '(' + url + ')'
    tabsString.push('\n', url)
    })
  return tabsString.join('')
  }
  getAllTabs()"

  local flag_help flag_pretty flag_json flag_csv flag_markdown flag_no_ext
  local output_path=("${PWD}/urls") # sets a default path and filename without extension
  local usage=(
    "chrome_get_all_urls_from_front_window [ -h | --help ]"
    "chrome_get_all_urls_from_front_window [ -p | --pretty-print ] [ -o | --output <path/to/file> ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {c,-csv}=flag_csv \
    {j,-json}=flag_json \
    {md,-markdown}=flag_markdown \
    {ne,-no-extension}=flag_no_ext \
    {p,-pretty-print}=flag_pretty \
    {o,-output}:=output_path || return 1

  [[ -n "$flag_help" ]] && { print -l $usage && return; }

  [[ -n "$flag_pretty" ]] && { \
    local urls_json="$(osascript -l JavaScript -e $to_json_script)" && \
      printf '%s' "$urls_json" | json && return; }

  [[ -n "$flag_csv" ]] && { \
    local urls_csv="$(osascript -l JavaScript -e "$to_csv_script")" && \
      echo "$urls_csv" >"$output_path[-1].csv" && \
      # code "$output_path[-1].csv" &&
      return; }

  [[ -n "$flag_json" ]] && { \
    local urls_json="$(osascript -l JavaScript -e $to_json_script)" && \
      echo "$urls_json" | json >"$output_path[-1].json" && \
      # code "$output_path[-1].json" &&
      return; }

  [[ -n "$flag_markdown" ]] && { \
    local urls_md="$(osascript -l JavaScript -e $to_md_script)" && \
      echo "$urls_md" >"$output_path[-1].md" && \
      # code "$output_path[-1].md" &&
      return; }

  [[ -n "$flag_no_ext" ]] && { \
    local urls_no_ext="$(osascript -l JavaScript -e $to_no_ext_script)" && \
      echo "$urls_no_ext" >"$output_path[-1]" && \
      # code "$output_path[-1].md" &&
      return; }

  [[ "$@" -eq "0" ]] && { \
    local urls_no_ext="$(osascript -l JavaScript -e $to_no_ext_script)" && \
      printf '%s\n' "$urls_no_ext" && return; }

}

# ! Dependency: get_urls_from_file function
function chrome_open_urls_from_file() {
  local chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

	[[ ! -x $chrome ]] && { \
    printf '%b\n' '\n[ERROR]: chrome is not installed or not found' && return 1; }

  [[ "$#@" -eq '0' ]] && { \
    printf '%b\n' '\n[ERROR]: no input was provided' && return 1; }

  local sleep_time=

  local flag_help flag_current_window urls
  local usage=(
  "chrome_open_urls_from_file [ -h | --help ]"
  "chrome_open_urls_from_file [ - | -- ] [ -o | --output <path/to/file> ]"
  )

  zmodload zsh/zutil
  zparseopts -D -F -K -- \
    {h,-help}=flag_help \
    {c,-current-window}=flag_current_window || return 1

    [[ -n "$flag_help" ]] && { print -l $usage && return; }

    [[ -n "$flag_current_window" ]] || { \
      chrome --new-window 2>/dev/null 1>/dev/null || return 1; }

    if [[ -f $1 ]]; then
        sleep "${sleep_time:-0}"
        file_content="$(get_urls_from_file $1)"
        urls=(${(@f)file_content})
      else
        urls=(${(@)@})
    fi

    open "${urls[@]}"

    # It is way faster to open all urls at once than to open them one by one in a loop, so don't do that:
    # for u in "${urls[@]}"; do
    #   echo $u
    #   open $u
    # done
}

# ! Dependencies: rg, jq, awk
function get_urls_from_file() {
  local file=$1
  local extension=${file##*.}
  local urls=""

  [[ "$extension" == "csv" ]] && urls="$(awk -F ',' '{i=2; if(NR>1) { print $NF}}' "$file")"

  [[ "$extension" == "json" ]] && urls="$(jq -r '.[].url' "$file")"

  [[ "$extension" == "md" ]] && urls="$(rg -No --no-column '(http.+).*$' "$file" | sed 's/)//g')"

  printf "%s" "${urls:-"$(cat $file)"}"
}

