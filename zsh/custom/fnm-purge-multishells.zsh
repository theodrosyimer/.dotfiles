#!/usr/bin/env zsh

####
## Delete the entries `fnm env` left in ~/.local/state/fnm_multishells.
##
## Every shell that ran `fnm env` created one entry, a symlink named <shell PID>_<milliseconds>,
## and fnm never deletes them. Since the Node shims (node-shims/fnm-exec) replaced the per-shell
## setup, nothing creates new ones.
##
## Only entries whose shell process has ended are deleted: a terminal opened before the shims
## still uses its entry for node. A PID macOS has since given to another process keeps its entry
## until that process ends too; run it again later.
##
## Prints how many entries were removed and kept per month they were created in, then totals.
##
## Usage:
##   fnm-purge-multishells              delete
##   DRY_RUN=1 fnm-purge-multishells    count only, no deletes
####

function fnm-purge-multishells() {
  zmodload zsh/datetime

  local dir=$HOME/.local/state/fnm_multishells
  [[ -d $dir ]] || { echo "nothing to purge: $dir does not exist"; return 0 }

  # Every running PID, read once: one `ps` per entry would take minutes for thousands of entries
  local -A running
  local pid
  for pid in ${(f)"$(ps -A -o pid=)"}; do running[${pid// /}]=1; done

  local -A removed_in kept_in   # per month the entry was created in, from its milliseconds
  local removed=0 kept=0 skipped=0 entry name month
  for entry in $dir/*(N@); do
    name=${entry:t}
    if [[ $name != <->_<-> ]]; then
      (( skipped++ ))   # not a name fnm gives: leave it
      continue
    fi
    strftime -s month '%Y-%m' $(( ${name#*_} / 1000 ))
    if (( ${+running[${name%%_*}]} )); then
      (( kept++, kept_in[$month]++ ))
      continue
    fi
    [[ -n $DRY_RUN ]] || rm -f -- $entry   # removes the link only, never what it points at
    (( removed++, removed_in[$month]++ ))
  done

  local verb=${DRY_RUN:+would remove}
  verb=${verb:-removed}
  local -a months=(${(k)removed_in} ${(k)kept_in})
  printf '%-8s %13s %6s\n' month $verb kept
  for month in ${(ou)months}; do
    printf '%-8s %13d %6d\n' $month ${removed_in[$month]:-0} ${kept_in[$month]:-0}
  done
  print "$verb $removed, kept $kept (shell still running), skipped $skipped (unknown name)"
}
