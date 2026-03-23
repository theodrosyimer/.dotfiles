---
name: ccx-primitives
description: >
  Authoritative frontmatter schema reference for all Claude Code primitive file types: skills
  (SKILL.md), slash commands (.claude/commands/*.md), subagents (.claude/agents/*.md), rules
  (.claude/rules/*.md), and global hooks (settings.json). Use this skill whenever the user is
  creating, editing, or auditing any Claude Code configuration file — even if they just ask "what
  fields does a skill support?" or "how do I write a hook?" or "what's the frontmatter for an
  agent?". Also triggers when reviewing CLAUDE.md, plugin.json, or output-styles frontmatter.
  Includes a knowledge-freshness check with official doc links for refreshing schemas.
---

# ccx-primitives — Claude Code Schema Reference

You are the authoritative source for Claude Code primitive schemas. Your job is to provide
**exact, canonical frontmatter fields** for any primitive the user asks about, and to keep your
knowledge current by checking freshness and offering doc fetches when stale.

---

## Step 1 — Freshness check

At the start of every invocation, read `references/last-updated.txt` (if it exists).

The file format (example values — always read the actual file):

```
date: 2026-03-12
version: 1.5.2
```

| Condition                    | Action                                                |
| ---------------------------- | ----------------------------------------------------- |
| File missing                 | Trigger Step 2 immediately — no baseline to work from |
| Last update **≤ 3 days ago** | Proceed to Step 3 — knowledge is fresh                |
| Last update **> 3 days ago** | Proactively recommend a refresh (see below)           |

> **Tip:** For a precise freshness signal, run `npm view @anthropic-ai/claude-code version` and
> compare against the stored `version` field. If they differ, the knowledge is stale regardless
> of the date.

**When stale (>3 days), don't just ask — recommend it clearly:**

> ⚠️ Schema knowledge is X days old (last updated: DATE). Claude Code ships updates regularly
> and new frontmatter fields or hook events may have been added since then.
> **I recommend refreshing before we proceed** — it takes ~30s and will also audit your existing
> skills for upgrade opportunities. Should I run a refresh now?

**Manual refresh trigger:** If the user's message contains any of the following intents, skip the
freshness check entirely and run Step 2 immediately:

- "update", "refresh", "sync", "fetch latest", "check for updates"
- "what's new in Claude Code", "any new features", "changelog"
- "audit my skills", "check my setup"

---

## Step 2 — Knowledge refresh (on user request or stale)

### 2a — Fetch primitive schemas

First, read `references/cc-documentation.md` for **anchor-specific URLs** that point directly to
each primitive's frontmatter reference section. Use these targeted URLs with `web_fetch` first —
they land on the exact section instead of requiring you to scan an entire page.

For broader context or if the anchor URL doesn't resolve, fall back to these full-page URLs using
`web_fetch` + a `web_search` with `site:code.claude.com` to cross-reference (web_fetch alone
misses JS-rendered content):

| Primitive         | Primary doc URL                                   |
| ----------------- | ------------------------------------------------- |
| Skills            | https://code.claude.com/docs/en/skills            |
| Slash commands    | https://code.claude.com/docs/en/slash-commands    |
| Subagents         | https://code.claude.com/docs/en/sub-agents        |
| Memory & rules    | https://code.claude.com/docs/en/memory            |
| Hooks reference   | https://code.claude.com/docs/en/hooks             |
| Hooks guide       | https://code.claude.com/docs/en/hooks-guide       |
| Settings          | https://code.claude.com/docs/en/settings          |
| Plugins           | https://code.claude.com/docs/en/plugins           |
| Plugins reference | https://code.claude.com/docs/en/plugins-reference |
| Output styles     | https://code.claude.com/docs/en/output-styles     |

Compare against `references/schemas.md` for any new or changed fields.
Update `references/schemas.md` with confirmed changes, marking additions with `🆕`.

### 2b — Read the changelog (new entries only)

Run this bash command to fetch only changelog entries since the last known version:

```bash
VER=$(grep '^version:' references/last-updated.txt | cut -d' ' -f2 || echo "NOMATCH"); \
curl -s "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md" | sed "/^## ${VER}$/q"
```

The `sed` command stops (inclusive) at the stored version's header — only newer entries are
returned. If `$VER` is empty or not found in the changelog (file corrupt, version pruned from
history), the guard falls back to `NOMATCH` and sed returns the full file — safe but verbose.

From the output, extract:

- New frontmatter fields added to any primitive
- New hook events or handler types
- New CLI flags or settings keys
- Deprecated fields or behavior changes
- Any feature that could improve existing skills, agents, or hooks

### 2c — Audit existing project skills

After reading the changelog, scan both project-level and user-level Claude Code config files:

```bash
# Project-level
find .claude/ -type f \( \
  -path "*/skills/*/SKILL.md" \
  -o -path "*/agents/*.md" \
  -o -path "*/commands/*.md" \
  -o -path "*/rules/*.md" \
  -o -name "settings.json" \
  -o -name "plugin.json" \
\) 2>/dev/null

# User-level (~/.claude/)
find ~/.claude/ -type f \( \
  -path "*/skills/*/SKILL.md" \
  -o -path "*/agents/*.md" \
  -o -path "*/commands/*.md" \
  -o -path "*/plugins/*/plugin.json" \
\) 2>/dev/null

# Dotfiles (~/.dotfiles/claude/) — user's personal plugin source
find ~/.dotfiles/claude/ -type f \( \
  -path "*/skills/*/SKILL.md" \
  -o -path "*/agents/*.md" \
  -o -path "*/commands/*.md" \
  -o -path "*/plugins/*/plugin.json" \
  -o -name "settings.json" \
\) 2>/dev/null
```

For each file found, check:

1. **Schema correctness** — any fields that are invalid for that primitive type?
2. **Changelog opportunities** — does any new feature from 2b apply to this file?
3. **Anti-patterns** — any known gotchas from `references/schemas.md` section 9?

Present findings as a prioritized list:

- 🔴 **Errors** — invalid fields, wrong schema, will break behavior
- 🟡 **Upgrades** — new features from changelog that could improve this file
- 🔵 **Suggestions** — anti-patterns or style improvements

### 2d — Finalize

Parse the latest version from the top of the changelog slice (first line matching `^## X.Y.Z`).
Write both fields to `references/last-updated.txt`:

```
date: <today ISO 8601>
version: <latest version from changelog>
```

Summarize: what changed in schemas, what changed in changelog, what was flagged in the audit.

---

## Step 3 — Answer

Read `references/schemas.md` and answer the user's question with:

1. The **complete field table** for the requested primitive(s)
2. Which fields are **required vs optional**
3. **Gotchas** and **anti-patterns** from the notes section in schemas.md
4. A minimal working example

When the user is creating a new file, generate a complete frontmatter block with all relevant
fields, sensible defaults filled in, and unused optional fields commented out.

When auditing an existing file, compare field-by-field against the schema and flag:

- Unknown fields (may be hallucinated or from a different primitive type)
- Missing required fields
- Fields used in the wrong primitive (e.g., `context: fork` in a command file)

**If `schemas.md` doesn't cover the question** (topic missing, field unclear, or user asks about
something not in the reference), fall back in this order:

1. Read `references/cc-documentation.md` for anchor-specific URLs to the relevant primitive's
   frontmatter docs — fetch that URL directly
2. If no matching link exists, use the full-page URLs from the Step 2a table
3. Do NOT guess or infer from training data alone — Claude Code changes frequently and training
   data may be stale.

---

## Reference files

- `references/schemas.md` — All frontmatter field tables, extracted from official docs. Read this
  before answering any schema question.
- `references/cc-documentation.md` — Direct links to official frontmatter schema docs with section
  anchors. Use these URLs for targeted fetches instead of searching entire pages.
- `references/last-updated.txt` — Date and version of last knowledge refresh (`date:` + `version:`
  fields). Read at every invocation.

If `references/schemas.md` is missing or empty, trigger a knowledge refresh immediately (Step 2)
without asking — there's no baseline to work from.
