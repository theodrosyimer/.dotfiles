---
name: context-optimizer
description: >
  Manage and optimize CLAUDE.md, .claude/rules/, and nested context files for Claude Code projects.
  Use this skill whenever the user asks to audit, restructure, evolve, or maintain their agent context files.
  Also trigger when: the user says "audit my context", "optimize my CLAUDE.md", "update context from this session",
  "restructure my rules", "what should go in my CLAUDE.md", or references context file management.
  This skill applies research-backed principles from ACE (Agentic Context Engineering) and empirical studies
  on AGENTS.md effectiveness to keep context files minimal, non-redundant, and high-signal.
---

# Context Optimizer

Manage Claude Code context files using research-backed principles. Context files should contain **only what the agent cannot discover by reading the codebase** — landmines, non-obvious conventions, and tooling gotchas. Everything else is noise that degrades performance and inflates cost.

## Core Principles (from research)

1. **Discoverability filter**: If the agent can find it by reading code, `package.json`, or directory structure — don't put it in context files
2. **Landmines only**: Non-obvious gotchas, surprising conventions, things the agent would get wrong without being told
3. **Context competes with the task**: Every line in a context file competes for attention with the actual prompt — less is more
4. **Rules constrain, skills instruct**: Rules = "never do X" (auto-loaded guardrails). Skills = "here's how to do Y" (on-demand playbooks)
5. **Incremental deltas, not rewrites**: When evolving context, add/remove individual bullets — never rewrite entire files
6. **Treat context as diagnostic**: Each line signals a codebase smell. Fix the root cause, then delete the line

## Four Modes

### Mode 1: Audit — "Audit my context files"

Analyze existing context files and produce a concrete report.

**Steps:**

1. Read root `CLAUDE.md`
2. List and read all `.claude/rules/*.md` files
3. Scan for nested `CLAUDE.md` files in child directories
4. For each line/section, classify using the checklist in `references/audit-checklist.md`
5. Produce a report with:
   - **KEEP** — genuine landmines, non-discoverable constraints
   - **SCOPE** — correct content but needs `paths:` frontmatter to avoid loading on every task
   - **MOVE TO SKILL** — implementation details ("how") that belong in a skill, not a rule
   - **DELETE** — discoverable from codebase, redundant, or noise
   - **PROMOTE TO CLAUDE.md** — critical constraint buried in a rule/skill that should be in the root protocol file

**Critical audit questions per line:**
- Can the agent discover this by running `ls`, reading `package.json`, or grepping the codebase?
- Would the agent get this wrong without being told? (If no → delete)
- Does this apply to ALL tasks or only specific file types? (If specific → needs `paths:` scoping)
- Is this a constraint ("never do X") or instruction ("here's how to do X")? (Instruction → skill, not rule)
- Is this already stated elsewhere in context files? (If yes → deduplicate)

### Mode 2: Evolve — "Update context from this session"

Capture friction from the current session and propose incremental deltas.

**Steps:**

1. Identify what went wrong or caused friction in the current session
2. Apply the diagnostic question: **"Is this a codebase smell I should fix, or a context rule I should add?"**
   - If codebase smell → suggest the code/config fix, not a context addition
   - If genuine non-discoverable constraint → propose a delta
3. For each proposed delta:
   - Write it as a single bullet (one constraint, one line)
   - Determine placement: CLAUDE.md vs scoped rule vs skill reference
   - Check for redundancy against existing context files
   - Apply discoverability filter: would a fresh agent session hit this same problem?
4. Present the delta for user approval before adding

**Delta format:**
```markdown
## Proposed Context Delta

**Trigger**: [What went wrong in this session]
**Diagnosis**: [Codebase smell vs context gap]
**Proposed addition**:
  - File: `.claude/rules/schema-first.md`
  - Content: `- Never use z.lazy() for recursive types — use explicit type assertion instead`
**Redundancy check**: [Not found in existing rules/CLAUDE.md]
```

**Grow-and-refine principle (from ACE):**
- New items get appended with a unique identifier
- If a delta contradicts an existing bullet, replace it (don't add both)
- Periodically audit for bullets that are no longer relevant (codebase changed)

### Mode 3: Restructure — "Restructure my context files"

Reorganize context files to match the optimal 3-layer architecture.

**Read `references/restructure-guide.md` before executing this mode.**

**Target architecture:**

```
CLAUDE.md                          ← Layer 1: Protocol file (routing + landmines)
.claude/rules/                     ← Layer 1b: Scoped constraints (auto-loaded per path)
  schema-first.md                     paths: modules, api, front modules
  design-tokens.md                    paths: design-system, ui, front tsx
  caching.md                          paths: infrastructure, api, front hooks
.claude/skills/                    ← Layer 2: On-demand playbooks (loaded when needed)
  development/feature-implement/
  development/testing/
  ...
apps/<app>/CLAUDE.md               ← Layer 2b: Directory-scoped context (on-demand, only if needed)
packages/<package>/CLAUDE.md        ← Layer 2b: Directory-scoped context (on-demand, only if needed)
```

Layer 2b files are created only when a directory has landmines that don't fit in a scoped rule. Don't pre-create them — let friction reveal which directories need them.

**Steps:**

1. Run Mode 1 (Audit) first to classify all existing content (skip if no context files exist yet)
2. Apply the restructure guide to redistribute content
3. If root `CLAUDE.md` exists → optimize it. If missing → **create it** from `references/claude-md-template.md`
4. Scope existing rules with `paths:` frontmatter where missing
5. Identify content that should become nested `CLAUDE.md` files in child directories — **create them** if they don't exist (keep under 20 lines each, exceptions only)
6. Present the full restructure plan for user approval before executing

**Bootstrap scenario** (no context files exist yet):
- Skip audit — nothing to classify
- Interview the user: communication preferences, known landmines, MCPs/tools in use
- Generate root CLAUDE.md from template
- Do NOT auto-generate rules — wait for friction to emerge (Mode 2/4)

### Mode 4: Create Rule — "Create a rule for X"

Validate and create a new `.claude/rules/` file, enforcing the constraint-vs-instruction separation.

**Steps:**

1. **Collect the raw input** — what the user wants to codify as a rule
2. **Apply the 4-gate filter** (all must pass to create a rule):

```
Gate 1: CONSTRAINT CHECK
  "Is this a constraint/prohibition, or an implementation guide?"
  → Constraint ("never do X", "always use Y") → PASS
  → Implementation guide ("here's how to do X") → REJECT → belongs in a skill

Gate 2: DISCOVERABILITY CHECK
  "Can the agent find this by reading the code?"
  → YES → REJECT → it's redundant noise
  → NO → PASS

Gate 3: REDUNDANCY CHECK
  "Does this already exist in CLAUDE.md, another rule, or a skill's SKILL.md?"
  → Read CLAUDE.md, scan all .claude/rules/*.md files
  → YES → REJECT → deduplicate (or update existing rule instead)
  → NO → PASS

Gate 4: SCOPE CHECK
  "Does this apply to ALL tasks or only specific file types?"
  → ALL TASKS → Consider promoting to CLAUDE.md instead of a rule
  → SPECIFIC PATHS → PASS → will add paths: frontmatter
```

3. **Determine placement:**
   - Universal constraint (all tasks) → add to CLAUDE.md Landmines section
   - Path-specific constraint → create or append to scoped `.claude/rules/` file
   - If appending to existing rule file, check it stays under 60 lines

4. **Draft the rule content:**
   - Each constraint as a single bullet
   - "Never/Always/Must" language — no "consider" or "prefer"
   - Short code examples only if they clarify a constraint (3 lines max)
   - No implementation patterns, templates, or step-by-step guides

5. **Add `paths:` frontmatter** for scoped rules:
   ```yaml
   ---
   paths:
     - "packages/modules/**/*.ts"
     - "apps/api/**/*.ts"
   ---
   ```

6. **Present for user approval** before writing the file

**Naming convention for rule files:**
- Use the domain concept: `schema-first.md`, `caching.md`, `design-tokens.md`
- NOT the technology: `zod.md`, `redis.md`, `tailwind.md`
- NOT generic: `rules.md`, `conventions.md`, `guidelines.md`

## CLAUDE.md Protocol File Principles

The root CLAUDE.md should be a **routing document with landmines**, not a codebase overview. It should contain:

1. **Communication style** — how the agent should interact (non-discoverable)
2. **Critical landmines** — project-wide "never do X" rules that apply to ALL tasks
3. **Tool routing** — MCPs, doc fetching strategy (non-obvious)
4. **Skill routing** — minimal pointers to key skills for common workflows
5. **Active context maintenance instruction** — tells the agent to flag friction for evolution

**It should NOT contain:**
- Codebase overview, directory structure, tech stack description
- Commands (discoverable from package.json)
- Workflow sequences (discoverable from skill descriptions)
- Anything the agent finds by reading the repo

## Embedding Active Context Maintenance

Add this to the root CLAUDE.md to enable semi-active evolution:

```markdown
## Context Maintenance
If you encounter something surprising, confusing, or that caused you to make a mistake in this project,
flag it as a comment: "CONTEXT_FLAG: [description of the friction]". These flags indicate either:
1. A codebase smell that should be fixed (preferred), OR
2. A missing context rule that should be added via the context-optimizer skill
```

## Reference Files

- `references/audit-checklist.md` — Detailed classification criteria for auditing context lines
- `references/restructure-guide.md` — Step-by-step restructure workflow with examples
- `references/claude-md-template.md` — Optimal CLAUDE.md template with rationale
- `references/research-summary.md` — Key findings from ACE, ETH Zurich, Lulla et al., and Arize AI studies
