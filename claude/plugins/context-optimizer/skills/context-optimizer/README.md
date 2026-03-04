# Context Optimizer

Stop bloating your CLAUDE.md. Keep only what the agent can't discover on its own.

> **Research-backed:** detailed context files *reduce* agent success rates while increasing cost 20%+. This skill applies those findings — [see why](#research-foundation).

## Quick Start

**First time setup** — you have no CLAUDE.md yet:
```
You: "Set up my context files"
→ Agent interviews you for communication prefs, landmines, tools
→ Creates an optimized CLAUDE.md (~20-30 lines)
→ No rules generated — those come from real friction later
```

**You already have context files** — audit them:
```
You: "Audit my context files"
→ Agent reads CLAUDE.md + all rules + nested context files
→ Produces a report: what to keep, delete, scope, or move
→ You approve → agent cleans up
```

## What To Do and When

### Your context feels bloated or you haven't reviewed it in a while
**→ Run an audit**
```
You: "Audit my context files"
```
**Outcome:** A report classifying every line as KEEP, DELETE, SCOPE, MOVE, or PROMOTE. You approve, agent executes.

### The agent just made a recurring mistake
**→ Evolve your context**
```
You: "Update context from this session"
```
**Outcome:** Agent diagnoses the friction, proposes a single-bullet fix in the right file. Never rewrites — only appends.

### The agent flagged something during work

Agents don't self-flag by default — you enable it by adding this to your CLAUDE.md:

```markdown
# Context Maintenance
If you encounter something surprising, confusing, or that caused a mistake in this project,
flag it: "CONTEXT_FLAG: [description]". These flags indicate either:
1. A codebase smell to fix (preferred), OR
2. A missing context rule to add via the context-optimizer skill
```

Once enabled, the agent will flag friction as it encounters it:
```
Agent: "CONTEXT_FLAG: Drizzle ORM requires explicit .execute() on insert"
```

When you see a flag, you have three options:
1. **Fix the codebase** (preferred) — eliminate the friction at the source, no context change needed
2. **"Add that as a rule"** — agent creates a scoped rule to prevent recurrence
3. **Ignore it** — one-off issue, not worth tracking

### You want to reorganize your entire context setup
**→ Restructure**
```
You: "Restructure my context files"
```
**Outcome:** Full redistribution across the 3-layer architecture. Before/after diff. You approve, agent executes.

### You want to add a new constraint
**→ Create a rule**
```
You: "Create a rule for [constraint]"
```
**Outcome:** Agent validates through 4 gates (is it a constraint? non-discoverable? non-redundant? scoped?). If it passes, creates the rule in the right place with proper `paths:` scoping.

## How Context Loads Per Session

```
Every session:
  → CLAUDE.md (always loaded, ~20-30 lines)
  → Rules WITHOUT paths: frontmatter (always loaded, same priority as CLAUDE.md)

When touching files matching a rule's paths: frontmatter:
  → + that rule (auto-loaded, high priority)

When agent needs implementation guidance:
  → Reads relevant skill on-demand
```

Unscoped rules load every session — use them only for truly universal constraints. The fewer rules that load, the less context competes with your actual task. This is why `paths:` scoping matters.

## Architecture

```
CLAUDE.md                          ← Always loaded. Communication + landmines + tool routing.
.claude/rules/                     ← Auto-loaded per path match. Constraints only.
.claude/skills/                    ← On-demand. Implementation guides.
apps/<app>/CLAUDE.md               ← On-demand. Directory-specific exceptions. Created by friction.
packages/<pkg>/CLAUDE.md           ← On-demand. Directory-specific exceptions. Created by friction.
```

**The principle:** Rules constrain ("never do X"). Skills instruct ("here's how to do Y"). CLAUDE.md routes and warns. Nothing else.

## What Makes a Good Context Line

✅ **Keep** — agent would get it wrong without being told:
```
- NEVER barrel files except package top-level
- vi.fn() ONLY for React component callback props
- Error maps = ExpectedErrors
```

❌ **Delete** — agent discovers it from code:
```
- This project uses TypeScript          ← tsconfig.json
- Run pnpm test to execute tests        ← package.json
- Directory structure: apps/, packages/  ← ls
```

## Over Time

Context files get tighter, not fatter:
1. **Audit** prunes noise and redundancy
2. **Evolve** captures real friction as single bullets
3. **Create Rule** validates before adding anything
4. Codebase fixes eliminate the need for context lines

Every context line is a signal about codebase friction. Fix the root cause, then delete the line.

---

## Research Foundation

This skill is built on findings from [*"Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?"*](https://arxiv.org/abs/2602.11988) (Gloaguen et al., ETH Zurich, Feb 2026).

**What they found** across multiple coding agents (Claude Code, Codex, Qwen Code) and benchmarks:

- **LLM-generated context files hurt**: −3% success rate on average, +20% inference cost
- **Developer-written files barely help**: +4% success rate, but still increase cost and steps
- **Codebase overviews are useless**: agents discover relevant files just as fast without them
- **Root cause**: agents are too obedient — they follow unnecessary requirements in context files even when counterproductive, leading to more exploration steps without better outcomes

**The paper's recommendation**: *"unnecessary requirements from context files make tasks harder, and human-written context files should describe only minimal requirements."*

**How this skill applies it**: only keep non-discoverable constraints, scope rules to relevant paths so they don't load unnecessarily, prune regularly through audits, and prefer fixing the codebase over adding context lines.
