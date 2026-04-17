# Session Handoff Document Template

> This template defines the structure of a handoff document. The SKILL.md procedure
> determines **when** and **how** to populate each section. Read the SKILL.md first —
> come here only when you need the exact output format.

---

## Template

```markdown
# Session Handoff — {task-name}

> Generated: {ISO-8601 timestamp}
> Session: {session-id or sequence number}
> Task scope: {one-line description of the overall task being handed off}

---

## 1. Completed Work

What was accomplished in this session. Each item must be verifiable — the next
session should be able to confirm completion without re-reading the full history.

### Files Changed

| File | Change type | Summary |
|------|-------------|---------|
| `path/to/file.ts` | created / modified / deleted | What changed and why |

### Decisions Made

Architectural or implementation decisions taken during this session that the next
session must respect. Include the reasoning — a decision without rationale is
useless to a fresh context.

- **Decision**: {what was decided}
  **Rationale**: {why — include constraints, tradeoffs, rejected alternatives}

### Tests Status

| Test suite / file | Status | Notes |
|-------------------|--------|-------|
| `path/to/test.ts` | passing / failing / new | What they cover, any known gaps |

---

## 2. Current State

The exact state of the codebase and task right now. The next session reads this
section first to orient itself.

### Working State

- **Branch**: {branch name}
- **Last commit**: {hash + message}
- **Build status**: {passing / failing — if failing, what breaks}
- **Test status**: {X passing, Y failing — list failing test names}

### In-Progress Work

Anything started but not finished. Be specific about where work stopped.

- {file or feature}: {what's done, what remains, where exactly to resume}

### Known Issues

Problems discovered but not yet fixed. Include reproduction steps if non-obvious.

- {issue}: {description, impact, any workaround attempted}

---

## 3. Next Steps

Ordered list of what the next session should do. Each step should be actionable
without requiring the next session to re-derive the plan from scratch.

1. {step}: {what to do, which files to touch, acceptance criteria}
2. {step}: {what to do, which files to touch, acceptance criteria}
3. ...

### Blocked Items

Anything that cannot proceed and why.

- {item}: {blocker, what's needed to unblock}

---

## 4. Context the Next Session Needs

Information that would be expensive for the next session to rediscover. This is
the section that justifies the handoff doc's existence — without it, the next
session wastes tokens re-exploring what this session already learned.

### Key Files to Read First

Files the next session should read before doing anything else, in priority order.

1. `path/to/file.ts` — {why this file matters for the next steps}
2. `path/to/other-file.ts` — {why}

### Domain Context

Business rules, constraints, or domain knowledge discovered during this session
that aren't documented elsewhere in the codebase.

- {context item}

### Gotchas and Warnings

Things that will trip up the next session if not flagged.

- {gotcha}: {what happens if ignored, how to handle it correctly}

### Relevant ADRs

ADRs that constrain the next steps. The next session should read these before
making architectural choices.

- `adrs/ADR-XXXX.md` — {title, why it's relevant}

---

## 5. Session Metrics (Optional)

Useful for tracking long-running tasks across many sessions.

- **Duration**: {approximate session duration}
- **Token usage**: {if known — helps calibrate future session planning}
- **Confidence**: {low / medium / high — how confident is this session that the
  next session can pick up cleanly from this doc alone}
```

---

## Section-by-Section Guidance

### Section 1 (Completed Work) — Anti-Patterns

- **Vague summaries**: "Updated the booking module" — useless. What files? What changed? Why?
- **Missing rationale on decisions**: A decision without reasoning forces the next session to either blindly follow it or waste tokens re-deriving the rationale
- **Omitting test status**: The next session needs to know which tests exist and whether they pass before making any changes

### Section 2 (Current State) — Anti-Patterns

- **Stale state**: If you ran tests 20 minutes ago and made changes since, re-run before writing this section
- **"Everything works"**: Be specific. Which tests pass? Does the build succeed? What's the actual output?
- **Hiding failures**: If something is broken, say so. The next session will discover it anyway — better to start with awareness than with surprise

### Section 3 (Next Steps) — Anti-Patterns

- **Over-specifying implementation**: "Use a Map<string, BookingEvent> with a private constructor and..." — this is the Planner anti-pattern from the harness design principles. Specify *what* to accomplish, not *how*. The next session should figure out the implementation path
- **Under-specifying acceptance criteria**: "Implement the search feature" — what does done look like? Which tests should pass? What behavior is expected?
- **Unbounded scope**: If the next steps exceed what one session can accomplish, break them into phases and mark the boundary

### Section 4 (Context) — Anti-Patterns

- **Duplicating CLAUDE.md**: Don't repeat project-wide conventions. Only include context *specific to this task* that the next session wouldn't get from the standard project setup
- **Listing every file in the module**: Prioritize ruthlessly. The next session has limited context — what are the 3-5 files it absolutely must read first?
- **Omitting gotchas**: If you spent 30 minutes debugging a subtle issue, that's exactly the kind of thing that belongs here. The next session will hit the same issue otherwise

### Section 5 (Metrics) — When to Include

Include metrics when the task spans multiple sessions and you want to track velocity, cost, or identify when context quality is degrading across handoffs. Skip for one-off handoffs.
