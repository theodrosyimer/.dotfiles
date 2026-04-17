---
name: session-handoff
description: >-
  Generate a structured handoff document for Claude Code session transitions.
  Use this skill whenever a session is ending (naturally or due to context
  degradation), when handing off work between agents or sessions, when the
  user says "handoff", "wrap up", "session summary", "pick up later",
  "continue in new session", "context is getting heavy", or when a long-running
  task needs to be split across multiple sessions. Also use when the user asks
  to "save progress", "checkpoint", or "pause and resume". This skill is
  critical for combating context degradation in long-running agentic tasks —
  even if the user doesn't explicitly ask for a handoff doc, suggest it when
  you detect the session has been running long or context quality is declining.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "<task-name or blank for auto-detect>"
---

# Session Handoff Document Generator

Generate a structured handoff document that enables a fresh Claude Code session
to pick up work cleanly without re-deriving context. This is the structured
artifact pattern from Anthropic's harness design principles — the fix for
context degradation in long-running tasks.

## Why This Exists

Context degradation is the #1 failure mode for long-running agentic tasks.
As the context window fills, coherence drops and models exhibit "context
anxiety" — wrapping up prematurely or losing track of the plan. The fix is
a **context reset** (fresh session) combined with a **structured handoff
artifact** that carries enough state for the next agent to pick up cleanly.

Compaction (automatic summarization) is insufficient — it preserves continuity
but doesn't give the agent a clean slate. A handoff doc + fresh session does.

## Procedure

### Step 1 — Determine Task Scope

If `$ARGUMENTS` is provided, use it as the task name.

If blank, infer from the session:
- Read recent git history: `git log --oneline -10`
- Check current branch: `git branch --show-current`
- Check for uncommitted changes: `git status --short`
- Derive a concise task name from the above

### Step 2 — Gather State

Collect the information needed to populate the handoff doc. Do this
systematically — don't rely on memory of the session.

**Git state:**
```bash
git branch --show-current
git log --oneline -20
git status --short
git diff --stat
```

**Build and test state:**
```bash
# Run the project's test command — check package.json for the exact script
# Typically: pnpm test, pnpm test:use-cases, or similar
# Capture pass/fail counts and failing test names
```

**Changed files this session:**
```bash
# Files changed since the branch diverged from main (or since last handoff commit)
git diff main --name-status 2>/dev/null || git diff HEAD~10 --name-status
```

**In-progress work:**
```bash
# Check for TODO/FIXME/HACK markers in recently changed files
git diff main --name-only 2>/dev/null | head -20 | xargs grep -n 'TODO\|FIXME\|HACK' 2>/dev/null || true
```

### Step 3 — Gather Decisions

Review the session for architectural or implementation decisions. Sources:
- Recently created or modified ADRs: `fd -e md . adrs/ 2>/dev/null | head -10`
- Comments in changed files indicating design choices
- Any patterns established that the next session must continue

### Step 4 — Determine Next Steps

Based on the current state, define what the next session should do:
- What's the immediate next task?
- What files should the next session read first?
- Are there any blockers?
- What gotchas were discovered that would be expensive to rediscover?

**Critical principle — constrain deliverables, not implementation paths.**
Tell the next session *what* to accomplish, not *how* to implement it.
Granular technical specs from a handoff cascade errors downstream — the next
session has fresh context and may find a better path.

### Step 5 — Write the Handoff Document

Read the template: `@references/handoff-template.md`

Populate every section using the data gathered in steps 2-4. Follow these rules:

1. **Every claim must be verifiable.** The next session should be able to confirm
   any statement in the doc by running a command or reading a file
2. **Prioritize ruthlessly.** The "Key Files to Read First" section should have
   3-5 files maximum. The next session has limited context — don't waste it
3. **Include the reasoning, not just the decision.** A decision without rationale
   is useless to a fresh context that can't ask "why?"
4. **Flag gotchas prominently.** If you spent significant time debugging something
   subtle, that's the highest-value content in the handoff doc
5. **Don't duplicate project-wide conventions.** CLAUDE.md and rules/ exist for
   that. Only include context *specific to this task*
6. **Be honest about failures.** If something is broken, say so. The next session
   will discover it anyway

### Step 6 — Save the Document

Save to the project's docs directory with a timestamped name:

```bash
# Create handoff docs directory if it doesn't exist
mkdir -p .claude/handoffs

# Save with ISO date prefix for chronological ordering
# Format: YYYY-MM-DD-{task-name}.md
```

The file goes in `.claude/handoffs/` so:
- It's discoverable by the next session via standard file exploration
- It's git-trackable (useful for multi-session task archaeology)
- It doesn't pollute the main docs/ directory
- Multiple handoffs for the same task sort chronologically

### Step 7 — Inform the User

After saving, tell the user:
1. Where the handoff doc was saved
2. The command to start a fresh session that picks up from the handoff:
   ```
   claude
   > Read .claude/handoffs/{filename} and continue from where the previous session left off.
   ```
3. If the session has been particularly long or complex, recommend a context
   reset (new session) rather than continuing in the current one

## Quality Checklist

Before finalizing, verify:

- [ ] Files Changed table has actual file paths, not summaries
- [ ] Decisions include rationale, not just the choice
- [ ] Test status reflects a *current* run, not a stale one
- [ ] Next Steps are ordered and have acceptance criteria
- [ ] Key Files list is prioritized (3-5 files max)
- [ ] Gotchas section exists if any non-obvious issues were encountered
- [ ] No project-wide conventions duplicated from CLAUDE.md
- [ ] Working State reflects the actual current branch/commit/build status

## When to Suggest a Handoff Proactively

Even if the user hasn't asked, suggest generating a handoff doc when:
- The session has been running for 30+ minutes on a complex task
- You notice your own responses becoming less coherent or more repetitive
- The task clearly won't finish in the current session
- The user mentions fatigue, needing a break, or coming back later
- Build/test state is complex and would be expensive to rediscover
