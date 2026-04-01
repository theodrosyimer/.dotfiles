# Anti-Patterns — Detection & Fix Reference

14 anti-patterns. Updated April 2026 (v2.1.89).
For each: detection signals to watch for in user descriptions, and the correct fix.

---

## Anti-pattern 1 — Workflow instructions in CLAUDE.md

**Detection signals:**
- User says "I put my deploy steps in CLAUDE.md"
- User describes CLAUDE.md with >200 lines of workflow instructions
- User asks why Claude is slow or context fills up quickly

**Why it's wrong:** CLAUDE.md loads every token, every turn. Workflow content that's only needed
sometimes pays full context cost all the time.

**Fix:** CLAUDE.md for conventions and architecture overview only (<200 lines). Workflows → skills.

---

## Anti-pattern 2 — Using CLAUDE.md as a hook substitute

**Detection signals:**
- User says "I wrote in CLAUDE.md to never touch .env files"
- User says "I told Claude to always run tests before committing" (in CLAUDE.md)
- User frustrated that Claude "forgot" a rule

**Why it's wrong:** CLAUDE.md is a suggestion. Claude can ignore it. Hooks are deterministic.

**Fix:** Anything with "never" or "must always" → PreToolUse or PostToolUse hook.

---

## Anti-pattern 3 — Side-effect workflow without invocation protection

**Detection signals:**
- User describes a workflow that deploys, sends messages, deletes data, or modifies external state
- Using a slash command for this (🆕 model can now invoke commands via SlashCommand tool)
- Using a skill without `disable-model-invocation: true`

**Why it's wrong:** Claude may decide to run the workflow autonomously at an unexpected moment.
A deploy workflow auto-triggered mid-session is a production incident. 🆕 This risk now applies
to both skills AND slash commands — commands can no longer be considered user-only.

**Fix:** Anything with side effects → skill with `disable-model-invocation: true`. Do NOT use a
slash command for side-effect workflows — you have no way to prevent model invocation on them.

---

## Anti-pattern 4 — Verbose workflow without context isolation

**Detection signals:**
- User describes a workflow that reads many files, runs audits, scaffolds multiple files, or chains subagents
- Using a slash command for this (no `context: fork` available)
- Using a skill but without `context: fork`

**Why it's wrong:** Verbose output degrades the main session. This is also the **primary reason
to choose a skill over a slash command** — if your workflow generates significant output,
`context: fork` on a skill is the correct call. A command cannot provide this isolation regardless
of how simple its body is.

Golden rule: >~20K tokens of output → `context: fork` or subagent.

**Fix:** Add `context: fork` to the skill. If currently a command, graduate it to a skill — the
only thing you're adding is `context: fork` in the frontmatter and a directory structure.

---

## Anti-pattern 5 — Agent teams for sequential work

**Detection signals:**
- User wants agent teams but describes tasks where B depends entirely on A
- Same-file edits across teammates
- User mentions agent teams for simple parallelism with no cross-communication needed

**Why it's wrong:** Agent teams cost 3-4x tokens. Sequential dependencies or same-file work will
cause conflicts or idle agents.

**Fix:**
- Sequential dependency → subagent chaining or headless `--resume`
- Simple parallelism → parallel subagents
- Graduate to agent teams only when workers genuinely need to share findings mid-task

---

## Anti-pattern 6 — Stop hook without `stop_hook_active` check

**Detection signals:**
- User writes a Stop hook that blocks unconditionally
- No `stop_hook_active` check in the hook script

**Why it's wrong:** Infinite loop — hook blocks → Claude continues → tries to stop → hook blocks
again → forever.

**Fix:** Always check `stop_hook_active` in Stop hooks. If true, exit 0 unconditionally.

```bash
INPUT=$(cat)
ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$ACTIVE" = "true" ]; then exit 0; fi
# ... rest of validation logic
```

---

## Anti-pattern 7 — Omitting `tools` on subagents

**Detection signals:**
- User's subagent frontmatter has no `tools` field
- User wants a read-only reviewer subagent but hasn't restricted tools

**Why it's wrong:** Omitting `tools` gives the subagent ALL tools including MCP — full write
access, all connected services.

**Fix:** Always explicitly list what the subagent needs. Read-only reviewer: `tools: Read, Grep, Glob`.

---

## Anti-pattern 8 — Duplicating skill content in CLAUDE.md

**Detection signals:**
- User describes the same API conventions or rules appearing in both CLAUDE.md and a skill body
- User asks why context is large

**Why it's wrong:** Context cost paid twice — once at session start (CLAUDE.md), once on skill
invocation.

**Fix:** Conventions → CLAUDE.md. Workflows → skills. Reference material → skill supporting files
(only loaded on invocation, not at session start).

---

## Anti-pattern 9 — Same session for writing and reviewing

**Detection signals:**
- User describes a single skill/session that writes code and then reviews it
- User frustrated that code reviews feel too lenient or miss obvious issues
- Single `claude -p` call that implements then validates in the same turn

**Why it's wrong:** Claude is biased toward code it just wrote. It remembers its reasoning,
tradeoffs, and shortcuts — so it won't catch its own mistakes.

**Fix:** Any phase that evaluates output from a previous phase → separate context.
- Subagent reviewer (automatic isolation)
- Skill with `context: fork` for the evaluation phase
- Separate `claude -p` invocation for CI pipelines

---

## 🆕 Anti-pattern 10 — Catch-all hooks without `if` filtering

**Detection signals:**
- Hook with `matcher: "Bash"` runs a validation script on every single Bash command
- Script internally checks for specific patterns (e.g., `grep -q 'git push'`) and exits 0 for non-matches
- Multiple hooks all matching on `"Bash"` each running separate scripts

**Why it's wrong:** Every Bash command spawns a subprocess to run the script, even when the
command is clearly irrelevant (e.g., running `ls` triggers a git-push blocker). Wastes time
and adds latency to every tool call.

**Fix:** Add `if` field for pattern-level pre-filtering:
```json
{
  "matcher": "Bash",
  "hooks": [{
    "type": "command",
    "if": "Bash(git push*)",
    "command": "./scripts/block-force-push.sh"
  }]
}
```

The `if` field filters before the script runs — no subprocess spawned for non-matching commands.

**When catch-all is correct:** Scripts that genuinely inspect ALL commands (e.g., a CLI modernizer
that suggests `fd` over `find`, `rg` over `grep`). If you can't express the target as a single
`Bash(pattern)`, keep the catch-all.

---

## 🆕 Anti-pattern 11 — Long skill descriptions losing discoverability

**Detection signals:**
- Skill description is >250 characters
- Key use case is buried after boilerplate
- Skill doesn't trigger when it should — Claude can't match it to the user's request
- User says "Claude doesn't use my skill"

**Why it's wrong:** Skill descriptions are truncated at 250 characters in the skill listing.
If the key trigger words are after the cutoff, Claude never sees them. The total description
budget is 1% of the context window (fallback 8K chars) — many long descriptions crowd each
other out.

**Fix:** Front-load the key use case in the first sentence. Keep total description under 250 chars.
Move detailed context into the skill body or supporting files.

**Bad:** `"A comprehensive tool for analyzing, reviewing, and optimizing database queries across
multiple SQL dialects including PostgreSQL, MySQL, and SQLite, with support for query plan
analysis and index recommendations"`

**Good:** `"Optimize SQL queries. Use when reviewing slow queries, missing indexes, or query plans."`

---

## 🆕 Anti-pattern 12 — Setting `permissionMode` on subagents under auto mode

**Detection signals:**
- Parent session uses auto mode (user enabled via `/permissions` or `--permission-mode auto`)
- Subagent frontmatter has `permissionMode: plan` or `permissionMode: dontAsk`
- User frustrated that subagent ignores its permission restrictions

**Why it's wrong:** When the parent uses auto mode, all subagents inherit it. The `permissionMode`
field in subagent frontmatter is silently ignored. The auto mode classifier evaluates the
subagent's tool calls with the same block/allow rules as the parent session.

**Fix:** If you need to restrict a subagent under auto mode, use `tools` or `disallowedTools` to
limit what it can access. Tool restrictions are always enforced regardless of permission mode.
For read-only subagents: `tools: Read, Grep, Glob` — this prevents writes even under auto mode.

---

## 🆕 Anti-pattern 13 — Plugin subagents with unsupported fields

**Detection signals:**
- Plugin subagent definition includes `hooks`, `mcpServers`, or `permissionMode` fields
- User reports that hooks aren't firing or MCP servers aren't connecting for plugin subagents
- No errors — fields are silently ignored

**Why it's wrong:** For security, plugin subagents do NOT support `hooks`, `mcpServers`, or
`permissionMode`. These fields are silently dropped when loading agents from a plugin.

**Fix:** If the subagent needs these fields, copy the agent file from the plugin into
`.claude/agents/` or `~/.claude/agents/`. Project/user-level agents support all fields. The
higher-priority location wins over the plugin version.

---

## 🆕 Anti-pattern 14 — File-type guidance in CLAUDE.md instead of path-scoped primitives

**Detection signals:**
- CLAUDE.md has sections like "When working with TypeScript files...", "For React components..."
- Large CLAUDE.md with conditional guidance that only applies to specific file types
- User asks why context fills up or Claude is slow

**Why it's wrong:** All CLAUDE.md content loads every session, every turn. File-type-specific
guidance pays full context cost even when working on unrelated files.

**Fix:** Move file-type-specific guidance to scoped primitives:
- Short constraints → `.claude/rules/` with `paths` field (loads on demand when matching files opened)
- Detailed workflow guidance → Skill with `paths` field (loads only when relevant files touched)
- Universal conventions (apply to everything) → keep in CLAUDE.md

```yaml
# .claude/rules/react-patterns.md
---
paths:
  - "src/components/**/*.tsx"
  - "src/hooks/**/*.ts"
---
Use function components, never class components.
Prefer composition over prop drilling.
```
