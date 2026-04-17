#!/bin/bash
# Claude Code status line — 4 rows:
#   L0  Starship prompt (cwd + git)
#   L1  model  🧠 ctx%  ⚡ effort  user
#   L2  current ●●●○○○○○○○  pct%  ⟳ H:MM                  (5h rate limit)
#   L3  weekly  ●○○○○○○○○○  pct%  ⟳ MM-DD HH:MM           (7-day rate limit)
#
# All numbers come from Claude Code's stdin (`context_window` + `rate_limits`)
# — Anthropic's own enforcement values, not derived.
#
# Effort-level resolution (Claude Code 2.1.x, verified by grepping cli.js):
#   1. `claude --effort X` CLI flag → pinned for the session, beats everything.
#      Read via ps on the parent pid looked up through ~/.claude/sessions/<pid>.json.
#   2. Otherwise: max(user_setting, model_default) — Claude Code auto-upgrades
#      "high" to "xhigh" on Opus 4.7 because xhigh is the model default.
#      Settings hierarchy walked: user → user-local → project → project-local → enterprise.
#   3. xhigh/max downgrade to "high" on non-Opus-4.7 models.
#
# KNOWN GAP: `/effort <level>` slash command during a session is invisible here.
# Claude Code exposes no SlashCommand hook, doesn't log effort to the transcript,
# and doesn't include effort in the statusline stdin. Until one of those lands,
# mid-session effort changes won't be reflected until the next launch.
# Feature request if this matters: github.com/anthropics/claude-code

set -u
input=$(cat)

C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_CYAN=$'\033[36m'
C_MAGENTA=$'\033[35m'

color_for_pct() {
  local p=$1
  if   (( p >= 90 )); then echo "$C_RED"
  elif (( p >= 70 )); then echo "$C_YELLOW"
  else                     echo "$C_GREEN"
  fi
}

bar() {
  local p=$1
  (( p > 100 )) && p=100
  (( p < 0   )) && p=0
  local filled=$(( p / 10 ))
  local empty=$(( 10 - filled ))
  local col; col=$(color_for_pct "$p")
  local out="$col"
  local i
  for ((i=0; i<filled; i++)); do out+="●"; done
  out+="$C_DIM"
  for ((i=0; i<empty; i++));  do out+="○"; done
  out+="$C_RESET"
  printf '%s' "$out"
}

# Parse all stdin fields in a single jq pass (6 spawns → 1, saves ~25 ms).
# Tab-separated output, read with IFS.
IFS=$'\t' read -r cwd project_dir model model_id ctx_pct \
  cur_pct cur_reset wk_pct wk_reset session_id < <(
    jq -r '[
      .cwd                                       // "",
      .workspace.project_dir                     // .cwd // "",
      .model.display_name                        // "claude",
      .model.id                                  // "",
      (.context_window.used_percentage           // 0 | tostring),
      (.rate_limits.five_hour.used_percentage    // 0 | tostring),
      (.rate_limits.five_hour.resets_at          // 0 | tostring),
      (.rate_limits.seven_day.used_percentage    // 0 | tostring),
      (.rate_limits.seven_day.resets_at          // 0 | tostring),
      .session_id                                // ""
    ] | @tsv' <<<"$input"
  )

# ───────────────── L0: Starship ─────────────────
# Use the Claude-specific config (no $fill, no right-aligned modules). Claude
# Code allocates a fixed ~147-col pty to the statusline process, so $fill from
# the main config would stop mid-line in wider terminals.
STARSHIP_SHELL="" STARSHIP_CONFIG="/Users/ty/.dotfiles/starship/starship-claude.toml" \
  starship prompt --path "${cwd:-$PWD}"
echo

# ───────────────── L1: header ─────────────────

# Effort resolution — mirrors Claude Code's logic: user-set value wins unless
# the model's default is ranked higher (Claude auto-upgrades Opus 4.7 to xhigh
# even when settings.json says "high").
# Settings hierarchy (last defined wins): user → user-local → project → project-local → enterprise.
user_effort=""
for f in \
  "$HOME/.claude/settings.json" \
  "$HOME/.claude/settings.local.json" \
  "${project_dir:+$project_dir/.claude/settings.json}" \
  "${project_dir:+$project_dir/.claude/settings.local.json}" \
  "/Library/Application Support/ClaudeCode/managed-settings.json"
do
  [[ -z $f || ! -f $f ]] && continue
  v=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
  [[ -n $v ]] && user_effort="$v"
done

case "$model_id" in
  *opus-4-7*) default_effort="xhigh" ;;
  *opus-4-6*) default_effort="medium" ;;
  *)          default_effort="medium" ;;
esac

effort_rank() {
  case "$1" in
    low)    echo 1 ;;
    medium) echo 2 ;;
    high)   echo 3 ;;
    xhigh)  echo 4 ;;
    max)    echo 5 ;;
    *)      echo 0 ;;
  esac
}

if [[ -z $user_effort ]]; then
  effort="$default_effort"
elif (( $(effort_rank "$default_effort") > $(effort_rank "$user_effort") )); then
  effort="$default_effort"
else
  effort="$user_effort"
fi

# Session-scoped override from `claude --effort X` — beats everything.
# Find the pid via ~/.claude/sessions/<pid>.json whose sessionId matches.
if [[ -n $session_id ]]; then
  sess_file=$(grep -l "\"sessionId\":\"$session_id\"" ~/.claude/sessions/*.json 2>/dev/null | head -1)
  if [[ -n $sess_file ]]; then
    pid=$(basename "$sess_file" .json)
    cli_effort=$(ps -p "$pid" -o command= 2>/dev/null \
      | grep -oE -- '--effort[ =][a-z]+' | head -1 | awk '{print $NF}' | tr -d '=')
    [[ -n $cli_effort ]] && effort="$cli_effort"
  fi
fi

# Guard: xhigh/max downgrade if unsupported by current model
[[ $effort == "xhigh" && $model_id != *opus-4-7* ]] && effort="high"
[[ $effort == "max"   && $model_id != *opus-4-7* ]] && effort="high"

ctx_col=$(color_for_pct "$ctx_pct")
header="${C_CYAN}${model}${C_RESET}  🧠 ${ctx_col}${ctx_pct}%${C_RESET}"
[[ -n $effort ]] && header+="  ⚡ ${C_MAGENTA}${effort}${C_RESET}"
header+="  ${C_DIM}${USER}${C_RESET}"
printf '%s\n' "$header"

now=$(date +%s)

# ───────────────── L2: current (5h rate limit) ─────────────────
if (( cur_reset > 0 )); then
  remain=$(( cur_reset - now ))
  (( remain < 0 )) && remain=0
  remain_str=$(printf '%d:%02d' $((remain / 3600)) $(( (remain % 3600) / 60 )))
else
  remain_str="—"
fi

col=$(color_for_pct "$cur_pct")
printf 'current %s  %s%3d%%%s  %s⟳ %s%s\n' \
  "$(bar "$cur_pct")" "$col" "$cur_pct" "$C_RESET" "$C_DIM" "$remain_str" "$C_RESET"

# ───────────────── L3: weekly (7-day rate limit) ─────────────────
if (( wk_reset > 0 )); then
  reset_str=$(date -d "@$wk_reset" "+%m-%d %H:%M" 2>/dev/null \
           || date -r "$wk_reset" "+%m-%d %H:%M" 2>/dev/null)
else
  reset_str="—"
fi

col=$(color_for_pct "$wk_pct")
printf 'weekly  %s  %s%3d%%%s  %s⟳ %s%s\n' \
  "$(bar "$wk_pct")" "$col" "$wk_pct" "$C_RESET" "$C_DIM" "$reset_str" "$C_RESET"
