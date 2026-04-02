# Candidate Patterns — Brainstorm (April 2026)

13 novel patterns + 11 cross-pollinations + combining Claude Code v2.1.89 capabilities AND harness design principles.
Status: brainstorming — to be refined and promoted to patterns.md after validation.

---

## A. Codebase Immune System

**Primitives:** `PreToolUse` (`if`) + `PostToolUse` (⚠️ use `type: "prompt"` — `type: "agent"` broken on PostToolUse as of v2.1.89, re-test after upgrades) + `PermissionDenied` + `memory: project`

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

**Primitives:** `PostToolUse` (⚠️ use `type: "prompt"` — `type: "agent"` broken on PostToolUse as of v2.1.89, re-test after upgrades) + `memory: project` + `FileChanged` + subagent with `skills`

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

---

## H. GDPR PII Sentinel

**Primitives:** `PostToolUse` (⚠️ use `type: "prompt"` — `type: "agent"` broken on PostToolUse as of v2.1.89, re-test after upgrades) + `PreToolUse` (`if`) + `memory: project` + rule `paths`

Enforce "PII out of event payloads from day one" mechanically:

- `PostToolUse` on Edit/Write, scoped with `if: "Edit(**/events/**)"` or
  `if: "Edit(**/commands/**)"` — agent handler scans the changed file for fields that look
  like PII (email, name, phone, address, IP) appearing directly in event payloads
- Memory stores the **PII field catalog** per module ("booking module: guest email is PII,
  booking ID is not")
- Path-scoped rule in `.claude/rules/` loads GDPR guidance only when editing domain events
- PreToolUse blocks committing if PII detected in event schemas

**Key insight:** You have Forgettable Payloads and Crypto Shredding patterns. An agent that knows
_which_ fields are PII per module catches mistakes that regex can't — it understands domain
context. The memory accumulates your PII catalog automatically.

**Trigger signals:** "Enforce GDPR in event payloads", "catch PII leaks at edit-time",
"automate privacy-by-design checks", "build a PII catalog".

---

## I. Event Replay Regression Guard

**Primitives:** `PostToolUse` (command handler) + `Stop` hook + `memory: project` + skill `paths`

When you modify `evolve`, `project`, or `react` functions, automatically validate backward
compatibility:

- `PostToolUse` on Edit/Write, path-scoped to `**/domain/**` — runs the module's event replay
  tests
- `Stop` hook spawns agent that checks: "Did the evolve function change? If yes, do old events
  still produce the same state?"
- Memory stores **projection baselines** — known-good read model outputs for key event sequences
- Path-scoped skill with the replay testing workflow only loads when editing domain pure functions

**Key insight:** Your four pure functions (decide/evolve/project/react) are the contract. Changing
`evolve` can silently break replay of historical events. This catches it at edit-time, not after
deployment.

**Trigger signals:** "Validate event replay backward compatibility", "catch evolve function
regressions", "projection baseline testing", "event schema migration safety".

---

## J. Module Boundary Enforcer (Real-Time)

**Primitives:** `PostToolUse` (⚠️ use `type: "prompt"` — `type: "agent"` broken on PostToolUse as of v2.1.89, re-test after upgrades) + `memory: project` + `FileChanged` on `tsconfig.json`

Goes beyond ArchUnitTS tests — catches violations **before** you run tests:

- `PostToolUse` on Edit/Write spawns agent that reads the import graph of the changed file
- Checks: does this file import from another module without going through `contracts/`?
  Does it bypass the Gateway/ACL?
- Memory stores the **allowed dependency map** per module (booking → space via
  SpaceAvailabilityGateway, not direct import)
- `FileChanged` on `tsconfig.json` triggers re-analysis of path mappings

**Key insight:** Your modular monolith uses Gateway/ACL for inter-module communication. ArchUnitTS
catches violations in CI, but this catches them **at edit-time** with domain-aware explanations
("booking module must access space availability through SpaceAvailabilityGateway, not by
importing space domain directly").

**Trigger signals:** "Catch module boundary violations at edit-time", "enforce Gateway/ACL usage",
"real-time architecture validation", "prevent cross-module coupling".

---

## K. Decide/Evolve/Project/React Scaffolder

**Primitives:** Skill with `paths` + `context: fork` + `disable-model-invocation: true`

When building a new aggregate in a bounded context:

- Path-scoped to `packages/modules/src/*/domain/` directories
- Scaffolds all four pure functions + state type + event types + command types + discriminated
  unions with `_tag`
- Generates matching test file with fixture factory (`createXxxFixture()`) + fake
  (`XxxEventStoreFake`)
- Follows your naming: `{module}Decide()`, `{module}Evolve()`, state-level dispatch with outer
  switch on `state._tag`, inner switch on `command._tag` or `event._tag`
- `context: fork` because scaffolding output is verbose
- Uses `satisfies` over type annotation to preserve literal types for `_tag` fields

**Key insight:** Very specific conventions (state-level dispatch, `_tag` discriminated unions,
`satisfies` over `: Type`, `type` not `interface` for data shapes). A scaffolder that knows ALL
of them saves setup time per aggregate and prevents convention drift.

**Trigger signals:** "New aggregate", "new bounded context", "scaffold event-sourced entity",
"set up decide/evolve/project/react".

---

## L. Frontend-Backend Contract Sync Checker

**Primitives:** `FileChanged` + subagent + `memory: project`

Your "UI is fully independent of backend" philosophy means contracts are the seam:

- `FileChanged` on files in `contracts/dtos/` triggers a subagent
- Subagent reads the changed Zod schema, then scans Expo frontend for components that consume
  this DTO type via `z.infer<typeof Schema>`
- Checks: does the frontend still handle all fields? Are there new required fields the UI
  doesn't render?
- Memory stores **which React components consume which DTOs**

**Key insight:** With ports + fakes enabling independent UI development, the contract layer is the
only coupling. When a DTO schema changes, you need to know which screens break — before someone
reports it.

**Trigger signals:** "DTO changed, what breaks?", "contract sync between backend and frontend",
"Zod schema impact analysis", "which screens use this DTO?".

---

## M. Observability-Driven Incident Investigator

**Primitives:** MCP (Sentry + Grafana) + subagent + `context: fork` + `memory: project` + `/loop`

Your full Pino → OTel → Sentry → Grafana stack becomes a debugging pipeline:

- MCP connects to Sentry (errors) and Grafana (R.E.D metrics from spanmetrics connector)
- `/loop 15m` polls for new Sentry issues above threshold
- On anomaly: subagent with `context: fork` pulls the Sentry error + OTel trace (traceId from
  `PinoInstrumentation` auto-injection) + reads the relevant handler code
- Memory stores **past investigations**: "this error pattern in booking module was caused by
  race condition in concurrent evolve calls"
- Generates report: error → trace → code path → likely cause → suggested fix

**Key insight:** Your observability stack is already set up for this. `PinoInstrumentation`
auto-injects traceId/spanId, the spanmetrics connector derives R.E.D metrics — all the data is
there. This pattern closes the loop: observability data → code investigation → fix suggestion.

**Trigger signals:** "Correlate Sentry errors with code changes", "automated incident
investigation", "production debugging pipeline", "close the observability loop".

---

---

# Cross-Pollinations

Combinations across candidates A-M that are more than the sum of parts.

---

## X1. Immune System + GDPR Sentinel (A + H)

The immune system's memory layer includes GDPR-specific "antibodies." `PermissionDenied` logs
blocked PII access attempts. Over time, the PostToolUse agent learns which fields in which
modules are PII — not from a static catalog but from **incidents it caught and incidents auto
mode blocked**. The adaptive layer evolves to include privacy compliance, not just code quality.

---

## X2. Migration Convoy + Event Replay Guard (D + I)

When migrating event schemas (e.g., adding a field, splitting an event), convoy workers run
replay validation as part of their Stop hooks. The validator agent checks: old events replay
correctly through new evolve functions. Memory records migration edge cases ("when migrating
BookingRequested v1→v2, the `period` field split needs a default handler for v1 events").

---

## X3. Chameleon + Boundary Enforcer (E + J)

As you `cd` between modules, not only do path-scoped skills shift (DDD in domain, perf in infra),
but the `CwdChanged` hook also loads that module's **dependency allowlist** into env vars via
`CLAUDE_ENV_FILE`. The boundary enforcer's PostToolUse agent reads these vars and knows which
cross-module imports are legal for _this specific module_ — dynamic boundaries that follow you.

---

## X4. Telemetry Loop + Incident Investigator (C + M)

The `/loop` pulls BOTH Grafana metrics AND Sentry errors in one cycle. When p99 spikes, the
forked subagent correlates: recent git commits + R.E.D metric changes + Sentry exceptions +
OTel traces. Memory stores baselines AND past incidents — "last time booking endpoint p99 spiked,
it was the N+1 query in SpaceAvailabilityChecker." Historical context makes each investigation
faster than the last.

---

## X5. Architecture Guardian + Boundary Enforcer (F + J)

Single PostToolUse prompt handler (⚠️ `type: "agent"` broken on PostToolUse as of v2.1.89) does **both**: detects architectural novelty (new patterns,
new dependency directions) AND validates module boundaries. The memory serves dual purpose —
living dependency map + ADR repository. One hook invocation, two enforcement layers, one
coherent architectural knowledge base that grows over time.

---

## X6. Headless Review Pipeline + GDPR Sentinel (G + H)

The automated PR review includes GDPR scanning before posting. Claude reviews the diff, and
`defer` pauses before posting the review comment. But before the defer, a hook scans: "Does this
PR introduce PII in any event payload?" If yes, the review draft includes a GDPR violation flag
with specific field/file references. Human sees both code review + privacy assessment in one
deferred output.

---

## X7. Competitive Implementation + TDD/TPP (B + existing TDD agent)

The spec writer creates **TPP-ordered** tests (simplest transformation first). N workers
implement independently in worktrees. Stop hooks validate both test passage AND TPP compliance
(using the tpp-reviewer agent prompt that reads tpp-rules from disk). The winning implementation
is the one that follows TPP most faithfully while passing all tests — selection pressure for
clean, incremental code.

---

---

# Harness Design Principles — Applied to Candidate Patterns

Derived from Anthropic's "Harness Design for Long-Running Agentic Applications" (Prithvi
Rajasekaran). These principles cut across ALL candidate patterns and inform how to build,
calibrate, and evolve them.

Source: `docs/claude-code/harness-design-for-long-running-agentic-applications.md`

---

## HP1. Separate Generation from Evaluation (GAN-Inspired)

**Core insight:** Tuning a standalone evaluator to be skeptical is far more tractable than making
a generator critical of its own work.

**How it maps to our patterns:**

| Pattern | Generator | Evaluator | Gap / Enhancement |
|---|---|---|---|
| A. Immune System | Claude's main editing loop | PostToolUse prompt handler (⚠️ `type: "agent"` broken on PostToolUse as of v2.1.89) | Add calibrated rubric to memory |
| B. Competitive Impl | N worker agents | Tests only | **Gap**: needs tuned evaluator beyond pass/fail — grade TPP compliance, code quality with calibrated rubric + hard thresholds |
| D. Migration Convoy | Worker agents | Validator agent | Validator needs **calibrated criteria**: migration completeness, pattern adherence, edge case handling — not just "tests pass" |
| F. Architecture Guardian | Edit/Write operations | PostToolUse agent | Add few-shot examples of what counts as "architectural novelty worth documenting" |
| G. Headless Review | Claude's analysis | Human via `defer` | Already separated — human IS the evaluator |
| H. GDPR Sentinel | Event/command authoring | PostToolUse agent | Add calibrated PII examples per module |
| I. Replay Guard | evolve/project modifications | Stop hook + tests | **Enhancement**: if replay fails, send structured feedback — not just block, but WHY and WHERE the regression occurred |
| J. Boundary Enforcer | Import/code changes | PostToolUse agent | Add calibrated examples of allowed vs disallowed imports |
| X7. Competitive + TDD | N workers | tpp-reviewer prompt | Strengthen with calibrated TPP rubric + hard thresholds per transformation level |

**Takeaway:** Every PostToolUse prompt handler (⚠️ `type: "agent"` broken on PostToolUse as of v2.1.89) in our patterns IS a separate evaluator. Formalize
this — all evaluator handlers should have: calibrated criteria, few-shot examples in memory,
hard thresholds per criterion.

---

## HP2. Context Degradation + Resets with Structured Handoff

**Core insight:** Context fills → coherence drops → "context anxiety" (premature wrap-up).
Compaction alone doesn't eliminate anxiety. Context resets with structured handoff artifacts do.

**How it maps to our patterns:**

| Pattern | Natural context isolation | Handoff artifact |
|---|---|---|
| B. Competitive Impl | Each worker in worktree = fresh context | Spec/tests = handoff |
| C. Telemetry Loop | `context: fork` subagent = fresh per investigation | Memory baselines = handoff |
| D. Migration Convoy | Each worker in worktree = fresh context | Scout's migration guide = handoff artifact |
| M. Incident Investigator | `context: fork` = fresh per investigation | Memory stores past investigations = handoff |

**Patterns that need this but don't have it:**
- Any long-running TDD session — after many RED-GREEN-REFACTOR cycles, context degrades.
  Solution: chain subagents with file-based handoff between cycles.
- Complex multi-module implementations — context fills with cross-module exploration.
  Solution: use `context: fork` for each module's implementation phase.

---

## HP3. Self-Evaluation Bias (Three Failure Modes)

**Core insight:** Even a SEPARATE evaluator starts lenient. Three specific failure patterns:

1. **Self-talk rationalization**: Finds issue → talks itself out of blocking
2. **Superficial testing**: Happy paths only, misses edge cases
3. **Leniency toward LLM-generated output**: Biased even when separated

**Enhancement for ALL evaluator-type hooks (A, F, H, I, J):**

- **Hard thresholds** per criterion — fail ANY one = block. No "overall it's fine" escape.
- **Adversarial prompting**: "Your job is to find problems. You fail at YOUR job if you approve
  work that has issues. Look for edge cases, not happy paths."
- **Few-shot anti-calibration**: Include examples where the evaluator SHOULD have blocked but
  didn't. Memory stores these "missed catches" as negative calibration.
- **Iterative tuning loop**: Read evaluator logs → find judgment divergences from human
  judgment → update evaluator prompt. This is the article's core QA tuning methodology.

---

## HP4. Sprint Contracts (What "Done" Looks Like)

**Core insight:** Before building, agree on testable criteria for completion. Bridges the gap
between high-level user stories and testable implementation.

**How it maps to our patterns:**

| Pattern | Sprint contract equivalent | Enhancement |
|---|---|---|
| B. Competitive Impl | Spec/tests = contract | Add explicit "what done looks like" file BEFORE workers start |
| D. Migration Convoy | Scout's migration guide | Already a contract — add hard thresholds per criterion |
| I. Replay Guard | Memory-stored projection baselines | Baselines ARE the contract — "this event sequence must produce this exact state" |
| L. Contract Sync | Zod schema = contract between frontend/backend | Add impact checklist: required fields rendered, optional fields graceful, error states handled |
| Existing TDD agent | .claude/tdd-phase file | Extend: write `.claude/tdd-contract.md` with acceptance criteria before RED phase starts |

**Application to your existing workflow:**
- Your `feature-plan` skill outputs a PRD = sprint contract
- Your `implement-feature` skill = generator that works against the contract
- The Stop hook = evaluator that grades against the contract
- The `tpp-reviewer` = specialized evaluator for transformation quality

---

## HP5. Constrain Deliverables, Not Implementation Paths

**Core insight:** Planners should specify WHAT to build, not HOW. Granular technical specs from
a planner cascade errors downstream. Let the builder figure out the path.

**Validation of our existing patterns:**
- `feature-plan` specifies deliverables + acceptance criteria → correct
- `implement-feature` owns architecture decisions → correct
- K. Scaffolder constrains output structure (four functions + types + tests), not internal
  logic → correct
- D. Migration Convoy: scout specifies target pattern, workers choose path → correct

**Anti-pattern this creates:**
- A planner skill that specifies "use Gateway pattern X" or "implement with Drizzle query Y"
  is over-constraining. The planner should say "booking module must access space availability"
  and let the implementer choose the Gateway/ACL design.

---

## HP6. Every Component Is an Assumption — Stress Test Them

**Core insight:** Every harness component encodes an assumption about what the model can't do
on its own. Those assumptions go stale as models improve. The right move is methodical
simplification: remove one component at a time, review impact.

**Application to our .claude/ setup:**

| Component | Assumption it encodes | When to re-evaluate |
|---|---|---|
| TDD guard hook | Model won't respect RED/GREEN/REFACTOR phases on its own | When models improve at following multi-step workflows |
| PostToolUse lint/tsc hooks | Model produces code that doesn't compile or lint | When models improve at producing correct code first-pass |
| tpp-reviewer Stop hook | Model doesn't naturally follow TPP transformation order | When models internalize TPP from training data |
| Module boundary enforcer (J) | Model doesn't naturally respect import boundaries | When models improve at architectural awareness |
| GDPR sentinel (H) | Model doesn't naturally avoid PII in event payloads | When models internalize GDPR-by-design patterns |
| PreToolUse `if` filters | Model tries dangerous operations | When auto mode classifier catches everything |

**Methodology when new Claude version ships:**
1. List all hooks, skills, rules, subagents
2. For each: "What assumption does this encode?"
3. Remove ONE component, run representative tasks, compare output quality
4. If quality unchanged → component was no longer load-bearing → strip it
5. Reinvest freed complexity budget (HP9)

**What NOT to do:** Radical cuts that remove multiple components at once — obscures which pieces
were actually load-bearing.

---

## HP7. Communication via Files (Structured Handoff Artifacts)

**Core insight:** Agents communicate through files — one writes, another reads. Keeps work
faithful to spec without over-specifying.

**How it maps to our patterns:**

| Pattern | Handoff artifact | Location |
|---|---|---|
| D. Migration Convoy | Scout's migration guide | Memory or `.claude/migration-guide.md` |
| X8. Context Reset Chaining | Handoff artifact between subagents | `.claude/handoff.md` |
| X9. Sprint Contract | Contract file defining "done" | `.claude/contract.md` |
| I. Replay Guard | Projection baselines | `.claude/baselines/` directory |
| Existing TDD agent | Phase file | `.claude/tdd-phase` (already implemented) |

**General principle for our patterns:** When two agents need to coordinate, use a **file** — not
prompt injection, not memory, not conversation history. Files are inspectable, versionable,
and survive context resets.

---

## HP8. Evaluator Calibration (Few-Shot + Hard Thresholds)

**Core insight:** Out-of-the-box, Claude is a poor QA agent. Calibration requires: reading
evaluator logs → finding judgment divergences → updating prompts. Several rounds needed.

**Biggest gap in our current patterns.** Most PostToolUse prompt handler (⚠️ `type: "agent"` broken on PostToolUse as of v2.1.89)s have a prompt but no
calibration, no few-shot examples, no hard thresholds.

**Enhancement for every evaluator-type pattern:** Memory should store **calibration sets**:

```
CALIBRATION ENTRY FORMAT:
  input: "Added `guestEmail: string` to BookingRequestedEvent payload"
  expected_score: 0/5 (PII violation — BLOCK)
  reasoning: "Email is PII — must use Forgettable Payload pattern"

  input: "Added `bookingId: BookingId` to BookingConfirmedEvent payload"
  expected_score: 5/5 (safe — APPROVE)
  reasoning: "BookingId is a branded UUID, not PII"
```

**Self-correcting calibration loop:**
1. Evaluator makes a judgment
2. User overrides ("you should have blocked this" or "false positive")
3. Memory stores the correction as a new calibration entry
4. Next invocation, evaluator reads updated calibration
5. Over time, evaluator aligns with user's judgment

This maps directly to the article's iterative QA tuning methodology.

---

## HP9. Complexity Budget Reallocation

**Core insight:** When you simplify the harness (remove a component), don't just enjoy the
savings — reinvest the freed complexity budget into pushing the capability frontier.

**Examples for our setup:**

| Simplification | Freed budget | Reinvestment |
|---|---|---|
| Drop sprint-style TDD guard | Hook overhead per phase | Better TPP rubric calibration in Stop hook |
| Drop redundant ArchUnit PostToolUse hook | Script execution per edit | Domain-aware boundary memory (J) |
| Drop simple lint PostToolUse | tsc/lint on every edit | Architectural drift detection (F) |
| Drop per-sprint QA (model improved) | Evaluator invocations | Single end-of-run comprehensive evaluation |

**The interesting harness space doesn't shrink as models improve — it moves.** The frontier of
what's achievable shifts outward, and the work is to keep finding the next novel combination.

---

## HP10. Evaluator Value at the Capability Boundary

**Core insight:** Evaluators add high value for tasks AT THE EDGE of model capability, but add
overhead with little value for tasks well within the model's solo ability.

**Application to pattern selection:**

```
EVALUATOR VALUE MATRIX

  Task clearly within model capability:
    → Skip evaluator, save tokens
    → Example: simple CRUD handler, rename refactor

  Task AT THE EDGE:
    → Evaluator catches real gaps, high value
    → Example: complex event schema migration, cross-module Gateway design,
      GDPR-sensitive event payload design

  Task beyond model capability:
    → Evaluator alone insufficient — needs human oversight
    → Example: novel architectural patterns, production incident diagnosis
    → Use `defer` for human-in-the-loop
```

**Implication for our patterns:** Not every edit needs the full immune system (A). Apply
evaluator patterns selectively — use `if` field to scope evaluator hooks to high-risk edits
(domain events, cross-module imports, infrastructure changes) and skip them for low-risk edits
(test files, documentation, formatting).

---

---

# Meta-Pattern Cross-Pollinations (from Harness Principles)

---

## X8. Context Reset via Subagent Chaining (HP2 + HP7)

For long tasks where compaction isn't enough, chain subagents with structured file-based handoff:

1. Agent 1 works on phase, produces a handoff artifact (`.claude/handoff.md`)
2. Handoff artifact contains: what was done, what's left, key decisions made, files changed
3. Agent 2 starts with **fresh context**, reads the handoff artifact
4. Each agent gets a clean slate without context anxiety

**Claude Code primitives:** Subagent chaining via orchestrating skill + file-based communication.
Headless equivalent: `claude -p` + `--resume` with different prompts per phase.

**When to use:** TDD sessions with many cycles, multi-module implementations, any task exceeding
~50% context capacity.

---

## X9. Sprint Contract Stop Hooks (HP4 + HP1)

Formalize the sprint contract pattern for Stop hooks:

1. Before work starts, write `.claude/contract.md` with testable criteria
2. Each criterion has a **hard threshold** — fail any one = block
3. Stop hook's agent handler reads the contract file and grades against it
4. Agent handler uses **adversarial prompting** (HP3): "Find problems. You fail if you approve
   work with issues."

**Claude Code primitives:** Stop hook `type: "agent"` + contract file + memory for calibration.

**When to use:** Any pattern where "done" needs verification — TDD phases, migration steps,
feature implementation, code review.

---

## X10. Periodic Harness Audit (HP6 + `/loop` or scheduled)

Every hook, skill, rule, and subagent encodes an assumption. Audit them:

1. When a new Claude version ships, list all `.claude/` components
2. For each: document the assumption it encodes
3. Methodically remove ONE component, run representative tasks, compare quality
4. Strip what's no longer load-bearing
5. Reinvest freed complexity budget (HP9)

**Claude Code primitives:** Could be a skill invoked manually (`/harness-audit`) or a scheduled
trigger after model upgrades. Uses the `ccx-primitives` refresh to check for new capabilities
that obsolete existing components.

**When to use:** After every major Claude model release. After adding multiple new hooks/skills.
When sessions feel slow or context fills too quickly.

---

## X11. Self-Correcting Evaluator Calibration (HP3 + HP8 + memory)

Every evaluator-type pattern gets a calibration loop:

1. Evaluator makes judgment (approve/block) with reasoning
2. User observes the judgment — agrees or overrides
3. On override: memory stores a new calibration entry with:
   - The input that was misjudged
   - The correct judgment + reasoning
   - Whether it was a false positive (blocked when shouldn't) or false negative (approved when
     shouldn't)
4. Next invocation: evaluator reads calibration entries from memory before judging
5. Over time: evaluator aligns with user's judgment on domain-specific nuances

**Claude Code primitives:** PostToolUse prompt handler (⚠️ `type: "agent"` broken on PostToolUse as of v2.1.89) + `memory: project` + calibration file
format in memory directory.

**Applied to specific patterns:**
- H. GDPR Sentinel: learns which fields are PII per module
- I. Replay Guard: learns which state differences are acceptable vs regressions
- J. Boundary Enforcer: learns which cross-module imports are intentional vs violations
- F. Architecture Guardian: learns which patterns are novel vs established
- A. Immune System: accumulates "antibodies" from all of the above

**This is the article's most transferable insight:** The iterative tuning loop (read logs → find
divergences → update prompt) is what makes evaluators actually useful. Without calibration,
evaluators are noisy gatekeepers that developers learn to ignore.
