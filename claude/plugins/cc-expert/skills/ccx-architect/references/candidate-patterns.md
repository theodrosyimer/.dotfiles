# Candidate Patterns — Brainstorm (April 2026)

7 novel patterns combining Claude Code v2.1.89 capabilities in non-obvious ways.
Status: brainstorming — to be refined and promoted to patterns.md after validation.

---

## A. Codebase Immune System

**Primitives:** `PreToolUse` (`if`) + `PostToolUse` (agent handler) + `PermissionDenied` + `memory: project`

Multi-layered defense that **learns** over time:

- **Innate immunity**: `PreToolUse` hooks with `if` patterns block known-dangerous operations
  instantly (no script overhead)
- **Adaptive immunity**: `PostToolUse` agent handler checks if the edit introduced patterns that
  previously caused issues (reads from memory)
- **Threat logging**: `PermissionDenied` hook records what auto mode blocks and why — feeds back
  into memory
- **Antibody generation**: Over sessions, memory accumulates "this pattern in this module caused X"
  — agent-type handlers read it before evaluating

**Key insight:** Most quality gate setups are static (pattern → block). This one **evolves** — the
PostToolUse agent reads memory to check against historically problematic patterns, not just
hardcoded rules. The PermissionDenied hook closes the feedback loop.

**Trigger signals:** "I keep making the same mistakes", "we have recurring issues in this module",
"I want guardrails that learn from past incidents".

---

## B. Spec-Driven Competitive Implementation

**Primitives:** Agent teams + `isolation: worktree` + `Stop` hooks + `TaskCreated` validation

Tournament-style code generation for critical paths:

1. A "spec writer" agent writes tests/acceptance criteria (`plan` mode, read-only)
2. `TaskCreated` hook validates each task against the spec before agents start
3. N worker agents in isolated worktrees implement **independently** — no communication
4. `Stop` hooks on each worker validate against the spec (run tests)
5. Orchestrator compares implementations: test coverage, code complexity, performance

**Key insight:** Current patterns are "one agent implements." This uses agent teams as a
**selection mechanism** — competing implementations where the spec is the fitness function.

**Trigger signals:** "This is security-critical", "I need the most performant implementation",
"I want to see different approaches before choosing", high-stakes code where getting it wrong
is expensive.

---

## C. Telemetry-Driven Optimization Loop

**Primitives:** MCP (Grafana/Sentry) + `/loop` + `memory: project` + subagent + `context: fork`

Closes the observability → code feedback loop:

1. MCP connects to Grafana (metrics) and Sentry (errors)
2. `/loop 30m` periodically pulls latency percentiles, error rates, top exceptions
3. Memory stores performance baselines ("auth endpoint: p99 was 120ms on March 15")
4. When metrics drift beyond thresholds, subagent with `context: fork` investigates: reads
   recent git log, correlates code changes with metric changes
5. Agent generates a prioritized report: "p99 latency increased 40% since commit abc123 —
   likely caused by N+1 query in user-loader.ts:47"

**Key insight:** Makes Claude a **performance analyst** that continuously monitors production,
builds historical baselines in memory, and correlates code changes with metric changes — work
that normally requires a senior SRE.

**Trigger signals:** "I want to catch performance regressions early", "correlate deploys with
metric changes", "automated SRE analysis", "production health monitoring during session".

---

## D. Migration Convoy

**Primitives:** Agent teams + `isolation: worktree` + `initialPrompt` + `Stop` hooks + `skills` preloading + `memory: project`

Coordinated large-scale migration (React class → functional, REST → GraphQL, Jest → Vitest):

1. **Scout agent** (`initialPrompt` self-starts, `plan` mode): analyzes the target pattern,
   writes a migration guide to memory
2. **Worker agents** (worktree-isolated, `skills: [migration-guide]`): each migrates one module,
   reads the scout's guide from preloaded skill
3. **Validator agent** (`plan` mode, `memory: project`): reviews each worker's output against
   the migration guide, records edge cases to memory
4. `Stop` hooks run tests per worker, block if migration broke anything
5. Workers that pass get their worktree branches merged

**Key insight:** The scout → workers → validator chain means the migration guide is generated from
the **actual codebase** (not generic docs), workers get isolated branches so conflicts are
impossible, and the validator's memory accumulates edge cases that improve later migrations.
It's a **learning migration pipeline**.

**Trigger signals:** "Migrate X to Y across the whole codebase", "we have 50 modules to convert",
"large-scale refactoring", "framework upgrade across monorepo".

---

## E. Context-Aware Pair Programming (Monorepo Chameleon)

**Primitives:** `CwdChanged` + `CLAUDE_ENV_FILE` + skill `paths` + rule `paths` + `memory: project`

Claude's persona shifts as you navigate a monorepo:

- `CwdChanged` hook detects directory switch, writes module-specific env vars to `CLAUDE_ENV_FILE`
  (e.g., `MODULE=booking`, `LAYER=domain`)
- Path-scoped skills auto-activate: DDD patterns in `domain/`, performance focus in
  `infrastructure/`, coverage push in tests
- Path-scoped rules enforce module-specific constraints (naming conventions differ between layers)
- Memory stores per-module history: "booking module uses event sourcing, space module uses CRUD"

**Key insight:** Current skills/rules are static — they activate on file patterns. This creates a
**dynamic context** where Claude's expertise, constraints, and historical knowledge shift based on
where you are. In a large monorepo, Claude is effectively a different (specialized) pair
programmer in each bounded context.

**Trigger signals:** "Different modules have different patterns", "I want Claude to know which
module uses event sourcing vs CRUD", "monorepo with varied tech per package", "context-sensitive
assistance".

---

## F. Living Architecture Guardian

**Primitives:** `PostToolUse` (agent handler) + `memory: project` + `FileChanged` + subagent with `skills`

Automatic architectural drift detection and documentation:

1. `PostToolUse` on Edit/Write spawns an agent handler (sonnet, 120s timeout)
2. Agent reads the changed file, checks: "Does this introduce a new dependency direction?
   A new pattern? A cross-module import?"
3. If architectural novelty detected, agent writes/updates an ADR in memory
4. `FileChanged` on `package.json` or `tsconfig.json` triggers config drift analysis
5. Dedicated subagent with `memory: project` + architecture-analysis skill can be invoked for
   deep review

**Key insight:** ADRs go stale because nobody remembers to update them. This makes architectural
documentation **reactive** — it updates itself when the code changes. The memory acts as a living
architecture map that gets more accurate over time instead of less.

**Trigger signals:** "Our architecture docs are always outdated", "I want to catch architectural
violations early", "detect when someone introduces a new dependency pattern", "living
documentation".

---

## G. Headless Review-then-Merge Pipeline

**Primitives:** Headless `claude -p` + `defer` + `PermissionDenied` + MCP (GitHub) + hooks + `--resume`

Full autonomous PR review with human-in-the-loop at critical moments:

1. GitHub webhook triggers `claude -p "Review PR #123"` with MCP for GitHub access
2. Claude reads diff, runs analysis, drafts review comments
3. `PreToolUse` hook on MCP GitHub post-comment returns `{"permissionDecision": "defer"}` —
   pauses before posting
4. Human reviews Claude's draft review in the deferred state
5. `claude -p --resume` — hook re-evaluates, allows comment posting
6. If all checks pass, Claude approves PR. If not, requests changes.
7. `PermissionDenied` hook logs any operations that were blocked during review

**Key insight:** Current CI patterns are either fully autonomous (risky for public-facing comments)
or fully manual (slow). The `defer` decision creates a **surgical pause point** — Claude does all
the analysis work autonomously, but a human approves the public-facing output. Review quality of
AI with accountability of a human.

**Trigger signals:** "Automated PR review but I want final say", "CI review pipeline with
approval gate", "AI-assisted code review with human oversight", "draft reviews for me to approve".
