# Orchestrating AI Code Review at Scale

> **Source**: Ryan Skidmore (Cloudflare) — [Orchestrating AI Code Review at scale](https://blog.cloudflare.com/ai-code-review/)
>
> **Key Insight**: Effective AI code review isn't a single monolithic prompt — it's a CI-native orchestration system that spawns domain-specialised reviewer agents (security, performance, code quality, docs, release, compliance, conventions), coordinates them through a judge-pass coordinator, and routes model tiers by risk classification, all behind a composable plugin architecture that isolates VCS, AI provider, and compliance concerns.

---

## 1. Why Naive Approaches Fail

Cloudflare tried the obvious paths first and found they all hit the same wall. Off-the-shelf AI code review tools worked reasonably well but lacked the flexibility needed at Cloudflare's scale — thousands of repos, internal coding standards, custom compliance requirements. The next attempt — grabbing a git diff, stuffing it into a prompt, and asking for bugs — produced a firehose of vague suggestions, hallucinated syntax errors, and redundant advice about already-handled error cases.

The fundamental problem is that a single model with a massive generic prompt can't distinguish between a critical security vulnerability and a style nitpick. Engineers learn to ignore the noise, and the tool becomes useless. Skidmore's team concluded that the solution is **domain decomposition**: split the review into specialised agents with tightly scoped prompts that tell each agent exactly what to look for and — critically — what to ignore.

---

## 2. Architecture: Composable Plugin System

The system is built on a plugin architecture where each concern is isolated behind a `ReviewPlugin` interface with three lifecycle phases:

```
PLUGIN LIFECYCLE — Three Phases

  Phase 1: BOOTSTRAP (concurrent, non-fatal)
    → Template fetching, optional setup
    → If a plugin fails here, review continues without it

  Phase 2: CONFIGURE (sequential, fatal)
    → VCS provider connection, core setup
    → If this fails, review aborts (no point continuing)

  Phase 3: POST-CONFIGURE (async)
    → Fetch remote model overrides, final async setup
```

Plugins interact through a `ConfigureContext` API — they can register agents, add AI providers, set environment variables, inject prompt sections, and alter agent permissions. No plugin directly mutates the final configuration. The core assembler merges all contributions into the config file that the coding agent consumes.

### 2.1 Plugin Isolation Principle

VCS-specific coupling is isolated in a single `ci-config.ts` file. The GitLab plugin doesn't read AI Gateway configs. The AI provider plugin doesn't know about GitLab tokens. This means swapping from GitLab to GitHub (or any other VCS) only touches one plugin.

### 2.2 Plugin Roster

```
PLUGIN ROSTER — Typical Internal Review

PLUGIN                          RESPONSIBILITY
────────────────────────────────────────────────────────────────────
gitlab                          VCS provider, MR data, MCP comment server
cloudflare                      AI Gateway config, model tiers, failback chains
codex                           Internal compliance checking against engineering RFCs
braintrust                      Distributed tracing and observability
agents-md                       Verifies repo's AGENTS.md is up to date
reviewer-config                 Remote per-reviewer model overrides (Cloudflare Worker)
telemetry                       Fire-and-forget review tracking
```

---

## 3. Two-Layer Orchestration (Coordinator + Sub-Reviewers)

The system uses OpenCode (open-source coding agent) as the underlying agent runtime, chosen because it's a **server-first** architecture — sessions are created programmatically via SDK, not hacked around a CLI.

### 3.1 Layer 1: The Coordinator Process

The coordinator is spawned as a child process. The prompt is sent via `stdin` (not CLI args) to avoid `ARG_MAX` / `E2BIG` limits on large MR descriptions. Output arrives as JSONL on `stdout`:

```typescript
const proc = Bun.spawn(
  ["bun", opencodeScript, "--print-logs", "--log-level", logLevel,
   "--format", "json", "--agent", "review_coordinator", "run"],
  {
    stdin: Buffer.from(prompt),
    env: {
      ...sanitizeEnvForChildProcess(process.env),
      OPENCODE_CONFIG: process.env.OPENCODE_CONFIG_PATH ?? "",
      BUN_JSC_gcMaxHeapSize: "2684354560", // 2.5 GB heap cap
    },
    stdout: "pipe",
    stderr: "pipe",
  },
);
```

Key implementation details:

- **JSONL format** — each line is a self-contained JSON object. Unlike a JSON array, you don't need a closing `]` to parse — critical when child processes crash mid-stream and you need the debug logs most
- **Buffered flushing** — output is batched (100 lines or 50ms) to avoid `appendFileSync` performance death
- **Stream triggers** — specific JSONL events are watched: `step_finish` for token usage tracking, `error` for retry logic, and `step_finish` with `reason: "length"` for output truncation detection (auto-retry)
- **Heartbeat logging** — prints "Model is thinking... (Ns since last output)" every 30 seconds to prevent users cancelling jobs that appear stuck but are actually in extended thinking

### 3.2 Layer 2: The Review Plugin (spawn_reviewers tool)

Inside the OpenCode process, a runtime plugin provides the `spawn_reviewers` tool. When the coordinator decides to review code, it calls this tool, which launches sub-reviewer sessions through the SDK:

```typescript
// Create session as child of coordinator
const createResult = await this.client.session.create({
  body: { parentID: input.parentSessionID },
  query: { directory: dir },
});

// Send prompt asynchronously (non-blocking)
this.client.session.promptAsync({
  path: { id: task.sessionID },
  body: {
    parts: [{ type: "text", text: promptText }],
    agent: input.agent,
    model: { providerID, modelID },
  },
});
```

Each sub-reviewer runs in its own session with its own agent prompt. The coordinator doesn't control what tools sub-reviewers use — they can freely read source files, run grep, or search the codebase. They return findings as structured XML.

---

## 4. Specialised Agent Prompts (The Core of the System)

### 4.1 The "What NOT to Flag" Principle

Skidmore identifies this as where the actual prompt engineering value resides. Without negative boundaries, models produce a firehose of speculative warnings that engineers learn to ignore.

Example from the security reviewer prompt:

```
SECURITY REVIEWER PROMPT — Boundaries

WHAT TO FLAG:
  ✅ Injection vulnerabilities (SQL, XSS, command, path traversal)
  ✅ Authentication/authorisation bypasses in changed code
  ✅ Hardcoded secrets, credentials, or API keys
  ✅ Insecure cryptographic usage
  ✅ Missing input validation on untrusted data at trust boundaries

WHAT NOT TO FLAG:
  ❌ Theoretical risks that require unlikely preconditions
  ❌ Defense-in-depth suggestions when primary defenses are adequate
  ❌ Issues in unchanged code that this MR doesn't affect
  ❌ "Consider using library X" style suggestions
```

### 4.2 Structured Finding Format

Every reviewer produces findings in structured XML with a severity classification:

```
SEVERITY CLASSIFICATION — Finding Output

SEVERITY     MEANING                                          DOWNSTREAM BEHAVIOR
──────────────────────────────────────────────────────────────────────────────────
critical     Will cause an outage or is exploitable            Blocks merge
warning      Measurable regression or concrete risk            May block if pattern detected
suggestion   An improvement worth considering                  Informational only
```

### 4.3 Model Tiering by Agent Complexity

Not every agent needs the most expensive model:

```
MODEL ASSIGNMENT — By Agent Complexity

TOP-TIER (Claude Opus 4.7, GPT-5.4):
  → Review Coordinator ONLY
  → Hardest job: read output of 7 models, deduplicate,
    filter false positives, make final judgment
  → Needs highest reasoning capability

STANDARD-TIER (Claude Sonnet 4.6, GPT-5.3 Codex):
  → Code Quality, Security, Performance reviewers
  → Fast, relatively cheap, excellent at logic errors and vulns

LIGHTWEIGHT (Kimi K2.5):
  → Documentation, Release, AGENTS.md reviewers
  → Text-heavy tasks, lower complexity
```

All model assignments are overridable at runtime via the `reviewer-config` Worker.

### 4.4 Prompt Assembly and Injection Prevention

Agent prompts are built at runtime by concatenating the agent-specific markdown with a shared `REVIEWER_SHARED.md` containing mandatory rules. The coordinator's input is assembled from MR metadata, comments, previous review findings, diff paths, and custom instructions — all wrapped in XML structure.

**Prompt injection prevention** is critical because user-controlled content (MR descriptions) is embedded in prompts. The system strips XML boundary tags from all user content to prevent breakout:

```typescript
const PROMPT_BOUNDARY_TAGS = [
  "mr_input", "mr_body", "mr_comments", "mr_details",
  "changed_files", "existing_inline_findings", "previous_review",
  "custom_review_instructions", "agents_md_template_instructions",
];
const BOUNDARY_TAG_PATTERN = new RegExp(
  `</?(?:${PROMPT_BOUNDARY_TAGS.join("|")})[^>]*>`, "gi"
);
```

### 4.5 Token Optimization: Shared Context

The system avoids duplicating full diffs and MR context across all sub-reviewers:

```
TOKEN OPTIMIZATION — Shared Context Strategy

  ❌ BAD: Embed full diff in each sub-reviewer prompt (7x token cost)

  ✅ GOOD:
    1. Write per-file patch files to a diff_directory
    2. Pass the path — each reviewer reads only patches relevant to its domain
    3. Extract shared-mr-context.txt from coordinator's prompt → write to disk
    4. Sub-reviewers read this shared file instead of each getting their own copy

  RESULT: 85.7% cache hit rate, estimated 5-figure savings per month
```

---

## 5. Coordinator Judge Pass

After all sub-reviewers complete, the coordinator performs a consolidation pass with three operations:

### 5.1 Deduplication

If the same issue is flagged by both security and code quality reviewers, it gets kept once in the section where it fits best.

### 5.2 Re-categorisation

A performance issue flagged by the code quality reviewer gets moved to the performance section.

### 5.3 Reasonableness Filter

Speculative issues, nitpicks, false positives, and convention-contradicted findings get dropped. If the coordinator isn't sure, it uses its tools to read the source code and verify.

### 5.4 Approval Decision Rubric

```
APPROVAL RUBRIC — Coordinator Decision Matrix

CONDITION                                    DECISION                 VCS ACTION
──────────────────────────────────────────────────────────────────────────────────────
All LGTM, or only trivial suggestions        approved                 POST /approve
Only suggestion-severity items               approved_with_comments   POST /approve
Some warnings, no production risk            approved_with_comments   POST /approve
Multiple warnings suggesting risk pattern    minor_issues             POST /unapprove (revoke prior bot approval)
Any critical item, or production safety risk significant_concerns     /submit_review requested_changes (block merge)
```

The bias is **explicitly toward approval**. A single warning in an otherwise clean MR still gets `approved_with_comments`, not a block.

### 5.5 Break Glass Escape Hatch

If a human reviewer comments `break glass`, the system forces an approval regardless of AI findings. This is detected before the review even starts, tracked in telemetry, and protects against latent bugs or LLM provider outages. Usage: only 0.6% of MRs (288 out of 48,095 in the first month).

---

## 6. Risk Tier Classification

Every MR is classified into a risk tier before agents are spawned, determining which agents run and which model tier is used:

```typescript
function assessRiskTier(diffEntries: DiffEntry[]) {
  const totalLines = diffEntries.reduce(
    (sum, e) => sum + e.addedLines + e.removedLines, 0
  );
  const fileCount = diffEntries.length;
  const hasSecurityFiles = diffEntries.some(
    e => isSecuritySensitiveFile(e.newPath)
  );

  if (fileCount > 50 || hasSecurityFiles) return "full";
  if (totalLines <= 10 && fileCount <= 20)  return "trivial";
  if (totalLines <= 100 && fileCount <= 20) return "lite";
  return "full";
}
```

Security-sensitive files (anything touching `auth/`, `crypto/`, or security-related paths) always trigger a full review.

```
RISK TIER → AGENT CONFIGURATION

TIER      LINES    FILES   AGENTS   WHAT RUNS                                           AVG COST
─────────────────────────────────────────────────────────────────────────────────────────────────
Trivial   ≤10      ≤20     2        Coordinator (downgraded to Sonnet) + 1 generalised   $0.20
Lite      ≤100     ≤20     4        Coordinator + code quality + docs + (more)            $0.67
Full      >100     >50     7+       All specialists incl. security, perf, release         $1.68
```

---

## 7. Diff Filtering Pipeline

Before agents see any code, the diff is filtered to strip noise:

```
DIFF NOISE FILTERING

LOCK FILES (always stripped):
  bun.lock, package-lock.json, yarn.lock,
  pnpm-lock.yaml, Cargo.lock, go.sum,
  poetry.lock, Pipfile.lock, flake.lock

MINIFIED/BUNDLED EXTENSIONS (always stripped):
  .min.js, .min.css, .bundle.js, .map

GENERATED FILES:
  ✅ Strip files with markers: // @generated, /* eslint-disable */
  ❌ EXCEPTION: Database migrations — tools stamp them as generated but
     they contain schema changes that MUST be reviewed
```

---

## 8. Concurrent Session Management (spawn_reviewers)

The `spawn_reviewers` tool acts as a scheduler for up to seven concurrent LLM sessions with circuit breakers, failback chains, per-task timeouts, and retry logic.

### 8.1 Session Completion Detection

Determining when an LLM session is "done" is tricky. The system uses a dual approach:

- **Primary**: OpenCode's `session.idle` events
- **Backup**: Polling loop every 3 seconds checking all task statuses
- **Inactivity detection**: Session running 60+ seconds with zero output → killed and marked as error (catches sessions that crash on startup before producing JSONL)

### 8.2 Three-Level Timeout Strategy

```
TIMEOUT HIERARCHY

LEVEL          VALUE      PURPOSE
──────────────────────────────────────────────────────
Per-task       5 min      Prevent one slow reviewer from blocking the rest
               10 min     (code quality — reads more files)
Overall        25 min     Hard cap for entire spawn_reviewers call
                          When hit → abort every remaining session
Retry budget   2 min min  Don't bother retrying if less than 2 min remain
```

---

## 9. Resilience: Circuit Breakers and Failback Chains

### 9.1 Circuit Breaker Pattern (Hystrix-inspired)

Each model tier has independent health tracking with three states:

```
CIRCUIT BREAKER — State Machine

  CLOSED (healthy)
    → All requests pass through
    → Tracks failure count
    → If threshold exceeded → OPEN

  OPEN (tripped)
    → All requests immediately fail
    → Failback chain activates
    → After 2-minute cooldown → HALF_OPEN

  HALF_OPEN (probing)
    → Allows exactly ONE probe request
    → If probe succeeds → CLOSED
    → If probe fails → OPEN (reset cooldown)
    → Prevents stampeding a struggling API
```

### 9.2 Failback Chains

When a circuit opens, the system walks a failback chain within the same model family:

```typescript
const DEFAULT_FAILBACK_CHAIN = {
  "opus-4-7":   "opus-4-6",    // Fall back to previous generation
  "opus-4-6":   null,          // End of chain
  "sonnet-4-6": "sonnet-4-5",
  "sonnet-4-5": null,
};
```

Model families are isolated — if one model is overloaded, it falls back to an older generation, not a different family.

### 9.3 Error Classification

When a sub-reviewer fails, the system decides whether to trigger model failback or not:

```
ERROR CLASSIFICATION — Failback Decision

ERROR TYPE              SHOULD FAILBACK?   REASON
──────────────────────────────────────────────────────────────────
APIError (429, 503)     YES                Retryable — different model might work
ProviderAuthError       NO                 Bad credentials — different model won't fix
ContextOverflowError    NO                 Token limit — different model has same limit
MessageAbortedError     NO                 User/system abort — not a model problem
StructuredOutputError   NO                 Schema issue — not model-dependent
```

### 9.4 Coordinator-Level Failback

The coordinator itself can also fail. The orchestration layer has a separate mechanism: if the child process fails with a retryable error (detected by scanning `stderr` for "overloaded" or "503"), it hot-swaps the coordinator model in the config JSON and retries. This is a file-level swap — read config, replace `review_coordinator.model`, write back, restart.

---

## 10. Remote Control Plane (Workers + KV)

### 10.1 Dynamic Model Routing

CI jobs fetch model routing configuration from a Cloudflare Worker backed by Workers KV. The response contains per-reviewer model assignments and a providers block:

```typescript
function filterModelsByProviders(models, providers) {
  return models.filter((m) => {
    const provider = extractProviderFromModel(m.model);
    if (!provider) return true;       // Unknown provider → keep
    const config = providers[provider];
    if (!config) return true;         // Not in config → keep
    return config.enabled;            // Disabled → filter out
  });
}
```

Flipping a switch in KV disables an entire provider — every running CI job routes around it within seconds. The config also carries failback chain overrides, allowing full model routing topology changes from a single Worker update.

### 10.2 Fire-and-Forget Telemetry

A `TrackerClient` talks to a separate Worker to track job starts, completions, findings, token usage, and Prometheus metrics. Design constraints:

- **Never blocks CI pipeline**: 2-second `AbortSignal.timeout` on all requests
- **Request pruning**: Drops pending requests if they exceed 50 entries
- **Batched metrics**: Prometheus metrics batched on next microtask, flushed before process exit
- **Forwarding**: Workers Logging → internal observability stack for real-time token burn monitoring

---

## 11. Re-Review System (Incremental Reviews)

When new commits are pushed to an already-reviewed MR, the system runs an incremental re-review. The coordinator receives its previous review comment and inline DiffNote comments with resolution status.

```
RE-REVIEW RULES

FIXED FINDINGS:
  → Omit from output
  → MCP server auto-resolves corresponding DiffNote thread

UNFIXED FINDINGS:
  → Must be re-emitted even if unchanged
  → Keeps the DiffNote thread alive

USER-RESOLVED FINDINGS:
  → Respected UNLESS the issue has materially worsened

USER REPLIES:
  → "won't fix" or "acknowledged" → treated as resolved
  → "I disagree" → coordinator reads justification, either resolves or argues back
```

Average MR gets 2.7 reviews (initial + re-reviews as engineer pushes fixes).

---

## 12. AGENTS.md Reviewer (Keeping AI Context Fresh)

A dedicated reviewer assesses whether an MR should trigger an update to the repo's `AGENTS.md` (or equivalent AI instruction file). The materiality classification:

```
AGENTS.MD MATERIALITY TIERS

HIGH (strongly recommend update):
  → Package manager changes
  → Test framework changes
  → Build tool changes
  → Major directory restructures
  → New required env vars
  → CI/CD workflow changes

MEDIUM (worth considering):
  → Major dependency bumps
  → New linting rules
  → API client changes
  → State management changes

LOW (no update needed):
  → Bug fixes
  → Feature additions using existing patterns
  → Minor dependency updates
  → CSS changes
```

The reviewer also penalises anti-patterns in existing AGENTS.md files:

```
AGENTS.MD ANTI-PATTERNS

  ❌ Generic filler ("write clean code") — not actionable
  ❌ Files over 200 lines — causes context bloat
  ❌ Tool names without runnable commands — not executable
  ✅ Concise, functional files with commands and boundaries
```

Teams can provide a URL to an AGENTS.md template that gets injected into all agent prompts — ensuring conventions apply across all repos without maintaining multiple files.

---

## 13. Deployment and Local Development

### 13.1 CI Integration

Ships as a GitLab CI component — a single `include` line:

```yaml
include:
  - component: $CI_SERVER_FQDN/ci/ai/opencode@~latest
```

The component handles Docker image, Vault secrets, review execution, and comment posting. Teams customise via `AGENTS.md` in repo root.

### 13.2 Local Development

A `@opencode-reviewer/local` plugin provides a `/fullreview` command inside OpenCode's TUI. It generates diffs from the working tree, runs the same risk assessment and agent orchestration, and posts results inline. Same agents, same prompts, just running locally.

---

## 14. Production Numbers (30-Day Window)

### 14.1 Volume and Speed

```
OPERATIONAL METRICS (March 10 – April 9, 2026)

METRIC                  VALUE
─────────────────────────────────────
Total review runs       131,246
Merge requests reviewed 48,095
Repositories            5,169
Avg reviews per MR      2.7 (initial + re-reviews)
Median review duration  3 min 39 sec
P90 duration            6 min 27 sec
P95 duration            7 min 29 sec
P99 duration            10 min 21 sec
Break glass usage       288 (0.6% of MRs)
```

### 14.2 Cost

```
COST DISTRIBUTION

PERCENTILE   COST PER REVIEW
─────────────────────────────
Median       $0.98
P90          $2.36
P95          $2.93
P99          $4.45

BY RISK TIER:
  Trivial    $0.20 avg / $0.17 median / $0.74 P99
  Lite       $0.67 avg / $0.61 median / $1.95 P99
  Full       $1.68 avg / $1.47 median / $5.05 P99
```

### 14.3 Findings Distribution

Total findings: 159,103 across all reviews (1.2 per review average — deliberately low, biased for signal over noise).

```
FINDINGS BY REVIEWER

REVIEWER         CRITICAL   WARNING   SUGGESTION   TOTAL     NOTES
────────────────────────────────────────────────────────────────────────────
Code Quality     6,460      29,974    38,464       74,898    ~47% of all findings
Documentation    155        9,438     16,839       26,432
Performance      65         5,032     9,518        14,615
Security         484        5,685     5,816        11,985    Highest critical %: 4%
Codex            224        4,411     5,019        9,654
AGENTS.md        18         2,675     4,185        6,878
Release          19         321       405          745       Only runs for release-related diffs
```

### 14.4 Token Usage

~120 billion tokens total. 85.7% cache hit rate — the prompt caching and shared context strategy are working.

```
TOKEN USAGE BY MODEL TIER

TIER           INPUT    OUTPUT   CACHE READ   CACHE WRITE   % OF TOTAL
──────────────────────────────────────────────────────────────────────────
Top-tier       806M     1,077M   25,745M      5,918M        51.8%
Standard-tier  928M     776M     48,647M      11,491M       46.2%
Kimi K2.5      11,734M  267M     0            0             ~0% cost

TOKEN USAGE BY AGENT

AGENT            INPUT    OUTPUT   CACHE READ   CACHE WRITE
────────────────────────────────────────────────────────────
Coordinator      513M     1,057M   20,683M      5,099M     (most output — writes full review)
Code Quality     428M     264M     19,274M      3,506M
Engineering      409M     236M     18,296M      3,618M
Codex
Documentation    8,275M   216M     8,305M       616M       (highest raw input — processes all file types)
Security         199M     149M     8,917M       2,603M
Performance      157M     124M     6,138M       2,395M
AGENTS.md        4,036M   119M     2,307M       342M
Release          183M     5M       231M         15M        (barely registers — conditional activation)
```

---

## 15. Known Limitations

Skidmore is transparent about what the system cannot do well:

```
LIMITATIONS — Not Yet Solved

ARCHITECTURAL AWARENESS:
  ❌ Reviewers see the diff and surrounding code, but don't understand
     WHY a system was designed a certain way or whether a change moves
     the architecture in the right direction

CROSS-SYSTEM IMPACT:
  ❌ Can flag an API contract change, but can't verify all downstream
     consumers have been updated

SUBTLE CONCURRENCY BUGS:
  ❌ Can spot missing locks, but not all the ways a system can deadlock
     (race conditions depend on timing/ordering beyond static diff analysis)

COST SCALING:
  ❌ 500-file refactors with 7 concurrent frontier models cost real money
  ❌ When coordinator prompt exceeds 50% of estimated context window,
     system emits a warning — large MRs are inherently expensive

POSITION:
  → This is NOT a replacement for human code review (with today's models)
  → It's a first-pass that catches bugs, enforces standards, and
     frees human reviewers to focus on architecture and design
```

---

## 16. Relevance to Our Work

This system maps directly to how a CI-integrated AI code review pipeline could be built for Parko using the existing stack and architecture patterns.

```
APPLICATION TO PARKO — AI CODE REVIEW SYSTEM

PLUGIN ARCHITECTURE → NestJS MODULE COMPOSITION:
  ✅ Maps to our modular monolith — each review concern is a module
     with its own contracts/ and infrastructure/
  ✅ Plugin isolation maps to our Gateway/ACL pattern —
     VCS plugin doesn't know about AI provider internals
  ✅ ConfigureContext API ≈ our DI container wiring pattern
  ❌ Don't build a monolithic reviewer — decompose by domain concern

AGENT PROMPT STRATEGY → PROMPT ENGINEERING:
  ✅ "What NOT to flag" sections are the highest-value prompt engineering
  ✅ Structured XML output with severity classification →
     parse into typed ADTs (critical/warning/suggestion discriminated union)
  ✅ Security reviewer should match our input validation rules (trust boundaries)
  ✅ Compliance reviewer → could check ADR compliance, module boundary violations
  ❌ Don't skip negative boundaries in prompts — they reduce noise 10x

MODEL TIERING → COST OPTIMIZATION:
  ✅ Maps to BullMQ job priority — different queues for different
     complexity tiers (trivial/lite/full)
  ✅ Risk assessment before spawning agents — don't burn tokens on typo fixes
  ✅ Coordinator needs top-tier model; sub-reviewers can use standard tier
  ❌ Don't use the most expensive model for every task

CIRCUIT BREAKER → RESILIENCE:
  ✅ Failback chains within model families (not across)
  ✅ Error classification: only retryable errors trigger failback
  ✅ Remote config via Worker/KV → instant provider disable without deploy
  ✅ Maps to our Sentry + Pino observability stack for monitoring
  ❌ Don't let auth errors or context overflow trigger model failback

RE-REVIEW SYSTEM → INCREMENTAL REVIEWS:
  ✅ Track previous findings + resolution status
  ✅ User replies ("won't fix", "acknowledged") → auto-resolve
  ✅ Re-emit unfixed findings even if unchanged (keeps threads alive)
  ✅ Maps to Emmett's event stream — review findings as events,
     re-review as projection over previous + new events

AGENTS.MD REVIEWER → CONVENTION ENFORCEMENT:
  ✅ Maps to our ADR immutability principle — detect when code changes
     contradict or aren't covered by existing ADRs
  ✅ Materiality tiers match our CRUD/CQRS/CROSS_CONTEXT classification
  ✅ Anti-pattern detection (generic filler, bloated files) →
     keep our .claude/skills/ lean and actionable

TOKEN OPTIMIZATION:
  ✅ Shared context file instead of duplicating per reviewer
  ✅ Per-file patch files — reviewers read only relevant patches
  ✅ 85.7% cache hit rate achievable with stable base prompts
  ❌ Don't embed full diffs in every sub-reviewer prompt (7x cost)

DIFF FILTERING:
  ✅ Strip lock files, minified assets, source maps before review
  ✅ Exception: database migrations (generated but must be reviewed)
  ✅ Maps to our Drizzle migration files — always review schema changes
```

---

## Summary

Cloudflare's AI code review system demonstrates that the path to production-quality AI review is not a better single prompt but architectural decomposition: specialised domain agents with tight positive/negative scope boundaries, coordinated by a judge-pass that deduplicates and filters with explicit approval bias, all behind a plugin system that isolates VCS, AI provider, and compliance concerns. The risk tiering system (trivial/lite/full) routes model spend to match diff complexity, circuit breakers with failback chains handle provider instability, and a remote control plane via Workers KV enables instant model routing changes without deploys. The "What NOT to Flag" prompt sections are the single highest-leverage engineering investment — they're what separate 1.2 useful findings per review from 10+ findings of dubious quality that engineers learn to ignore.

[^1]: Ryan Skidmore — [Orchestrating AI Code Review at scale](https://blog.cloudflare.com/ai-code-review/)
