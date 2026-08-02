# ─────────────────────────────────────────────────────────────────────────────
# Agent config sync
#
# SOURCE OF TRUTH
#   $CLAUDE_SRC — a PRIVATE repo, not part of these (public) dotfiles.
#   Cloned by ~/.dotfiles/bootstrap/claude.sh.
#
# WHAT ccsync DOES
#   Every agent (Claude Code, the `skills` CLI, codex) keeps its own config
#   directory. ccsync makes them all share one set of skills:
#
#     adopt   inbound  — a real directory sitting in ~/.claude, ~/.agents or
#                        ~/.codex is MOVED into $CLAUDE_SRC. Third-party skills
#                        (tracked in ~/.agents/.skill-lock.json) land in
#                        skills-vendor/, everything else in skills/.
#                        If it differs from a copy already in skills-vendor/ it
#                        wins — that is how an `npx skills update` lands. The
#                        same clash under skills/ is reported, never overwritten.
#     prune            — delete symlinks that are broken AND have no source.
#     link    outbound — symlink every skill in $CLAUDE_SRC into all three dirs.
#
#   Pass order matters: adopting before linking is what stops a skill from
#   existing as both a real directory in one place and a symlink in another.
#
# IDEMPOTENT
#   Unchanged entries print nothing. A second run is headers + a zero summary.
# ─────────────────────────────────────────────────────────────────────────────

: ${CLAUDE_SRC:=$HOME/dev/projects/personal/claude-code}
export CLAUDE_SRC

# ── helpers ──────────────────────────────────────────────────────────────────

# Abbreviate $HOME to ~ for readable output.
_cc_tilde() { print -r -- "${1/#$HOME/~}" }

# A skill is a directory containing SKILL.md. Everything else (loose files,
# arch__adr.zip, half-written skill dirs) is not linkable.
_cc_is_skill() { [[ -f "$1/SKILL.md" ]] }

# First source root that holds $1, or non-zero if none does.
_cc_find_source() {
  local name="$1"; shift
  local root
  for root in "$@"; do
    [[ -e "$root/$name" ]] && { print -r -- "$root/$name"; return 0 }
  done
  return 1
}

# Names installed by the `skills` CLI — these belong in skills-vendor/.
_cc_vendor_names() {
  local lock="$HOME/.agents/.skill-lock.json"
  [[ -f "$lock" ]] || return 0
  jq -r '.skills // {} | keys[]' "$lock" 2>/dev/null
}

# Link a single top-level file (CLAUDE.md, settings.json).
# Reads $force / $dry / counters / conflicts from the caller (zsh dynamic scope).
_cc_sync_file() {
  local src="$1" dest="$2"
  local name="${dest:t}"

  if [[ -L "$dest" ]]; then
    local cur="$(readlink "$dest")"
    if [[ "$cur" == "$src" ]]; then
      (( ++skipped ))
    elif $force; then
      $dry || { rm "$dest" && ln -s "$src" "$dest" }
      (( ++retargeted ))
      print "  ↻ $name (retargeted)"
      print "      at:  $(_cc_tilde "$dest")"
      print "      was: $cur"
      print "      now: $(_cc_tilde "$src")"
    else
      conflicts+=("$(_cc_tilde "$dest") → $cur (expected $(_cc_tilde "$src"))")
    fi
  elif [[ -e "$dest" ]]; then
    conflicts+=("$(_cc_tilde "$dest") (not a symlink, won't overwrite)")
  else
    $dry || ln -s "$src" "$dest"
    (( ++created ))
    print "  + $name"
    print "      $(_cc_tilde "$dest") → $(_cc_tilde "$src")"
  fi
}

# Link one source directory into one destination.
#
# Correctness is judged on the LITERAL link target, not realpath: a link may
# resolve to the right files through a chain (~/.claude/skills/x →
# ../../.agents/skills/x → $CLAUDE_SRC/skills/x) and still need retargeting to
# the direct path, otherwise removing the middle link silently breaks it.
_cc_link_one() {
  local src="$1" dest="$2"
  local name="${src:t}"

  if [[ -L "$dest" ]]; then
    local cur="$(readlink "$dest")"
    if [[ "$cur" == "$src" ]]; then
      (( ++skipped ))
    elif $force; then
      $dry || { rm "$dest" && ln -s "$src" "$dest" }
      (( ++retargeted ))
      print "  ↻ $name (retargeted)"
      print "      at:  $(_cc_tilde "$dest")"
      print "      was: $cur"
      print "      now: $(_cc_tilde "$src")"
    else
      conflicts+=("$(_cc_tilde "$dest") → $cur (expected $(_cc_tilde "$src"))")
    fi
  elif [[ -e "$dest" ]]; then
    conflicts+=("$(_cc_tilde "$dest") (not a symlink, won't overwrite)")
  else
    $dry || ln -s "$src" "$dest"
    (( ++created ))
    print "  + $name"
    print "      $(_cc_tilde "$dest") → $(_cc_tilde "$src")"
  fi
}

# Remove symlinks this sync will never (re)create. Takes the set of names the
# link pass considers valid; anything else is a leftover.
#
# A link is removed when its name is NOT valid and it either dangles or points
# into $CLAUDE_SRC. Two distinct leftovers are caught:
#
#   • the source is gone entirely (a renamed or deleted skill)
#   • the source still exists but is not linkable — a loose file such as
#     arch__adr.zip, or a directory with no SKILL.md. Those links resolve today
#     yet the link pass skips them, so without this they would linger forever
#     and dangle the moment the source moved.
#
# A valid name is never pruned even when broken: $CLAUDE_SRC moving breaks every
# link at once, and those belong to the link pass to retarget — reported as
# `retargeted`, not `pruned` + `created`. A link pointing somewhere unrelated to
# $CLAUDE_SRC is left alone; it is not ours to delete.
_cc_prune_dest() {
  local dest_dir="$1"; shift
  local -a valid=("$@")
  local item name real reason

  for item in "$dest_dir"/*(N); do
    [[ -L "$item" ]] || continue
    name="${item:t}"
    (( ${valid[(Ie)$name]} )) && continue

    real="$(realpath "$item" 2>/dev/null)"
    if [[ -z "$real" ]]; then
      reason="dangling, no source"
    elif [[ "$real" == "$CLAUDE_SRC"/* ]]; then
      reason="source is not a linkable skill"
    else
      continue                            # not ours — leave it alone
    fi

    local was="$(readlink "$item")"
    $dry || rm "$item"
    (( ++pruned ))
    print "  ✂ $name (pruned — $reason)"
    print "      was: $(_cc_tilde "$item") → $was"
  done
}

# ── ccsync ───────────────────────────────────────────────────────────────────

function ccsync() {
  local force=false adopt=false dry=false

  while (( $# )); do
    case "$1" in
      -f|--force)   force=true ;;
      -a|--adopt)   adopt=true ;;
      -n|--dry-run) dry=true ;;
      -h|--help)
        print "ccsync [--adopt] [--force] [--dry-run]"
        print ""
        print "  --adopt    move loose skill dirs from ~/.claude, ~/.agents and"
        print "             ~/.codex into \$CLAUDE_SRC (needs a clean git tree)"
        print "  --force    retarget symlinks that point somewhere else"
        print "  --dry-run  show what would change, write nothing"
        print ""
        print "  source: $(_cc_tilde "$CLAUDE_SRC")"
        return 0 ;;
      *) print "ccsync: unknown option '$1' (try --help)"; return 2 ;;
    esac
    shift
  done

  if [[ ! -d "$CLAUDE_SRC" ]]; then
    print "ccsync: \$CLAUDE_SRC not found at $(_cc_tilde "$CLAUDE_SRC")"
    print "        run ~/.dotfiles/bootstrap/claude.sh to clone it"
    return 1
  fi

  # Adoption MOVES directories. Refuse unless git can undo it.
  if $adopt && ! $dry; then
    if ! git -C "$CLAUDE_SRC" rev-parse --git-dir &>/dev/null; then
      print "ccsync: --adopt moves directories, so $(_cc_tilde "$CLAUDE_SRC") must be a git repo"
      return 1
    fi
    if [[ -n "$(git -C "$CLAUDE_SRC" status --porcelain)" ]]; then
      print "ccsync: --adopt needs a clean tree in $(_cc_tilde "$CLAUDE_SRC")"
      print "        commit or stash first, so the moves are reversible"
      return 1
    fi
  fi

  local created=0 skipped=0 retargeted=0 adopted=0 pruned=0
  local -a conflicts=() warnings=() candidates=()

  local -a src_roots=("$CLAUDE_SRC/skills" "$CLAUDE_SRC/skills-vendor")
  local -a skill_dests=("$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.codex/skills")
  local -a vendor_names=(${(f)"$(_cc_vendor_names)"})

  $dry && print "(dry run — nothing will be written)"

  # top-level files
  mkdir -p "$HOME/.claude"
  print "\n── link: $(_cc_tilde "$CLAUDE_SRC") → $(_cc_tilde "$HOME/.claude") ──"
  _cc_sync_file "$CLAUDE_SRC/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
  _cc_sync_file "$CLAUDE_SRC/settings.json" "$HOME/.claude/settings.json"

  # ── pass 1: adopt ──────────────────────────────────────────────────────────
  # `existing` is declared here, not in the loop: re-running `local name` on a
  # variable that already holds a value makes zsh echo it back like `typeset`.
  local dest_dir item name target_root target existing
  for dest_dir in "${skill_dests[@]}"; do
    [[ -d "$dest_dir" ]] || continue
    local header_shown=false

    for item in "$dest_dir"/*(N); do   # plain * skips .system/ and .DS_Store
      [[ -L "$item" ]] && continue
      [[ -d "$item" ]] || continue
      name="${item:t}"

      if ! _cc_is_skill "$item"; then
        warnings+=("$(_cc_tilde "$item") — no SKILL.md, not adopted")
        continue
      fi

      if (( ${vendor_names[(Ie)$name]} )); then
        target_root="$CLAUDE_SRC/skills-vendor"
      else
        target_root="$CLAUDE_SRC/skills"
      fi
      target="$target_root/$name"

      if ! $header_shown; then
        print "\n── adopt: $(_cc_tilde "$dest_dir") → $(_cc_tilde "$CLAUDE_SRC") ──"
        header_shown=true
      fi

      # Look for an existing copy in ANY source root, not just the routed one:
      # a skill can already live in skills/ while the lockfile routes it to
      # skills-vendor/, and adopting blindly would create a second copy.
      if existing=$(_cc_find_source "$name" "${src_roots[@]}"); then
        target="$existing"
        if diff -rq "$target" "$item" &>/dev/null; then
          # byte-identical duplicate — the copy outside is redundant
          if $adopt; then
            $dry || rm -rf "$item"
            (( ++adopted ))
            print "  = $name (identical copy removed)"
            print "      removed: $(_cc_tilde "$item")"
            print "      kept:    $(_cc_tilde "$target")"
          else
            candidates+=("$(_cc_tilde "$item") — identical to $(_cc_tilde "$target"), can be removed")
          fi
        elif [[ "$target" == "$CLAUDE_SRC/skills-vendor/"* ]]; then
          # Vendored skills are upstream-owned, and a content difference here is
          # what `npx skills update` produces. Let the incoming copy win rather
          # than stalling: --adopt already demands a clean tree, so git holds the
          # previous version — `git diff` reviews it, `git checkout` reverts it.
          # Skills under skills/ are yours and still refuse to be overwritten.
          if $adopt; then
            $dry || { rm -rf "$target" && mv "$item" "$target" }
            (( ++adopted ))
            print "  ⇤ $name (upstream update — repo copy replaced)"
            print "      from: $(_cc_tilde "$item")"
            print "      to:   $(_cc_tilde "$target")"
          else
            candidates+=("$(_cc_tilde "$item") → $(_cc_tilde "$target") — upstream update, will replace the repo copy")
          fi
        else
          conflicts+=("$name differs between $(_cc_tilde "$target") and $(_cc_tilde "$item")
      resolve: diff -rq $(_cc_tilde "$target") $(_cc_tilde "$item")")
        fi
      elif $adopt; then
        $dry || { mkdir -p "$target_root" && mv "$item" "$target" }
        (( ++adopted ))
        print "  ⇤ $name"
        print "      from: $(_cc_tilde "$item")"
        print "      to:   $(_cc_tilde "$target")"
      else
        candidates+=("$(_cc_tilde "$item") → $(_cc_tilde "$target")")
      fi
    done
  done

  # ── resolve the linkable set ────────────────────────────────────────────────
  # Done once, before pruning, because prune needs to know which names the link
  # pass will actually create. First root wins, so a skill present in both
  # skills/ and skills-vendor/ is reported instead of the two roots fighting
  # over the same link, and warnings are not repeated per destination.
  local src_root
  local -A skill_src
  local -a skill_order=()
  for src_root in "${src_roots[@]}"; do
    [[ -d "$src_root" ]] || continue
    for item in "$src_root"/*(N); do
      [[ -d "$item" ]] || continue            # skips loose files e.g. *.zip
      name="${item:t}"
      if ! _cc_is_skill "$item"; then
        warnings+=("$(_cc_tilde "$item") — no SKILL.md, not linked")
        continue
      fi
      if [[ -n "${skill_src[$name]}" ]]; then
        conflicts+=("$name is in two source roots: $(_cc_tilde "${skill_src[$name]}") and $(_cc_tilde "$item") — delete one")
        continue
      fi
      skill_src[$name]="$item"
      skill_order+=("$name")
    done
  done

  # ── pass 2: prune ──────────────────────────────────────────────────────────
  for dest_dir in "${skill_dests[@]}"; do
    [[ -d "$dest_dir" ]] || continue
    print "\n── prune: $(_cc_tilde "$dest_dir") ──"
    _cc_prune_dest "$dest_dir" "${skill_order[@]}"
  done
  if [[ -d "$HOME/.claude/hooks" ]]; then
    print "\n── prune: $(_cc_tilde "$HOME/.claude/hooks") ──"
    _cc_prune_dest "$HOME/.claude/hooks" "$CLAUDE_SRC"/hooks/*(N:t)
  fi
  if [[ -d "$HOME/.claude/rules" ]]; then
    print "\n── prune: $(_cc_tilde "$HOME/.claude/rules") ──"
    _cc_prune_dest "$HOME/.claude/rules" "$CLAUDE_SRC"/rules/*(N:t)
  fi

  # ── pass 3: link ───────────────────────────────────────────────────────────
  for dest_dir in "${skill_dests[@]}"; do
    mkdir -p "$dest_dir"
    print "\n── link: $(_cc_tilde "$CLAUDE_SRC") → $(_cc_tilde "$dest_dir") ──"
    for name in "${skill_order[@]}"; do
      _cc_link_one "${skill_src[$name]}" "$dest_dir/$name"
    done
  done

  # hooks + rules keep their one-way, whole-directory-contents behaviour
  local pair_src pair_dst
  for pair_src pair_dst in \
    "$CLAUDE_SRC/hooks" "$HOME/.claude/hooks" \
    "$CLAUDE_SRC/rules" "$HOME/.claude/rules"
  do
    [[ -d "$pair_src" ]] || continue
    mkdir -p "$pair_dst"
    print "\n── link: $(_cc_tilde "$pair_src") → $(_cc_tilde "$pair_dst") ──"
    for item in "$pair_src"/*(N); do
      _cc_link_one "$item" "$pair_dst/${item:t}"
    done
  done

  # ── summary ────────────────────────────────────────────────────────────────
  print "\n── summary ──"
  print "adopted: $adopted  created: $created  retargeted: $retargeted  pruned: $pruned  unchanged: $skipped"

  if (( ${#candidates[@]} )); then
    print "\nadoptable (${#candidates[@]}) — run 'ccsync --adopt' to move these into \$CLAUDE_SRC:"
    printf '  ⇤ %s\n' "${candidates[@]}"
  fi
  if (( ${#warnings[@]} )); then
    print "\nskipped (${#warnings[@]}):"
    printf '  ! %s\n' "${warnings[@]}"
  fi
  if (( ${#conflicts[@]} )); then
    print "\nconflicts (${#conflicts[@]}):"
    printf '  ✗ %s\n' "${conflicts[@]}"
    print "\nrun 'ccsync --force' to retarget wrong symlinks"
  fi
}

# ── plugins ──────────────────────────────────────────────────────────────────

function _cc_rm_plugin_cache() {
  rm -rf ~/.claude/plugins/cache/"${1:-ty}"/*
}

function ccpsync() {
  local src_dir="$CLAUDE_SRC/plugins"
  local cleared=()

  if [[ ! -d "$src_dir" ]]; then
    echo "No plugins source at $src_dir"
    return 1
  fi

  if (( $# )); then
    for name in "$@"; do
      if [[ -d "$src_dir/$name" ]]; then
        _cc_rm_plugin_cache "ty/$name"
        cleared+=("$name")
      else
        echo "  ✗ $name (not found in $src_dir)"
      fi
    done
  else
    for dir in "$src_dir"/*(N/); do
      _cc_rm_plugin_cache "ty/${dir:t}"
      cleared+=("${dir:t}")
    done
  fi

  if (( ${#cleared[@]} )); then
    echo "cache cleared: ${(j:, :)cleared}"
    echo "run /reload-plugins in Claude Code"
  else
    echo "no plugins to sync"
  fi
}

function skadd() {
	npx skills add https://github.com/theodrosyimer/claude-code/skills --skill "${1}"
}
