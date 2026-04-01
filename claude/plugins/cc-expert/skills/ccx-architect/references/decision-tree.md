# Decision Tree — Primitive Selection

Extracted from the Claude Code Orchestration Guide. Updated April 2026 (v2.1.89).

---

## Primary decision axes

Walk these in order. First match wins for the primary primitive.

### Axis 1 — Is it a rule Claude must ALWAYS follow?

| Answer                                     | Sub-question                                                     | Recommendation                                                                          |
| ------------------------------------------ | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Yes, must be deterministic — no exceptions | Applies to all invocations of a tool, or only specific patterns? | **Hook** (PreToolUse/PostToolUse to enforce)                                            |
| Yes, but soft guidance is OK               | Applies to all files, or only specific types?                    | **CLAUDE.md**, **.claude/rules/** (with `paths` for scoping), or **Skill** with `paths` |
| No, it's task-specific                     | → continue                                                       | → Axis 2                                                                                |

**Hook vs CLAUDE.md rule of thumb:** If the word "never" or "always" appears in the requirement,
it's a hook. If the word "prefer" or "try to" appears, it's CLAUDE.md or rules.

**Hook granularity:** Use `matcher` for tool-level filtering (e.g., all `Bash` commands), then `if`
for pattern-level filtering within that tool (e.g., only `Bash(git push*)`). The `if` field uses
permission rule syntax and avoids running scripts unnecessarily on non-matching commands.

---

### Axis 2 — Does it need external service access?

| Answer                                | Recommendation                                                                                                                                                 |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yes (GitHub, Sentry, DB, Slack, etc.) | **Use the tool's cli (e.g., `gh`, `sentry-cli`), if not available use a MCP server** — connect the service first, then wrap in a skill for orchestration logic |
| No                                    | → Axis 3                                                                                                                                                       |

---

### Axis 3 — Is it a repeatable workflow?

| Answer | Sub-question                                            | Recommendation |
| ------ | ------------------------------------------------------- | -------------- |
| Yes    | Should Claude invoke it autonomously, or only the user? | → Axis 3a      |
| No     | Is it a CI/CD pipeline or external script?              | → Axis 6       |

#### Axis 3a — Will it generate verbose output that would bloat the main session?

This is the **primary decision point** between a skill and a slash command.

| Answer                                                                | Recommendation                                                                     |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Yes — audit findings, scaffolded files, long logs, subagent summaries | **Skill** with `context: fork` — output stays isolated, only summary returns       |
| No — thin orchestration, short output                                 | **Slash command** — simpler, no directories, model-invocable via SlashCommand tool |

**Secondary considerations (only matter if context:fork isn't needed):**

| Need                                                | Recommendation                                                                           |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Must NEVER be model-invoked (side effects, deploys) | **Skill** with `disable-model-invocation: true` — commands cannot block model invocation |
| Model-only invocation (background knowledge)        | **Skill** with `user-invocable: false`                                                   |
| Everything else                                     | **Slash command** — lighter, sufficient                                                  |

---

### Axis 4 — Does it generate verbose output that would bloat context?

| Answer | Sub-question                           | Recommendation       |
| ------ | -------------------------------------- | -------------------- |
| Yes    | Do workers need to talk to each other? | → Axis 4a            |
| No     | —                                      | Inline skill is fine |

#### Axis 4a — Do parallel workers need to communicate?

| Answer                                             | Recommendation                                    |
| -------------------------------------------------- | ------------------------------------------------- |
| Yes — workers share findings, challenge each other | **Agent team** (experimental, 3-4x token cost)    |
| No — workers just report back to parent            | **Subagent(s)** or **Skill with `context: fork`** |

**Context cost thresholds (from Part 4):**

- Workflow generating > ~20K tokens of output → use `context: fork` or subagent
- Multiple parallel workstreams that don't communicate → parallel subagents
- Multiple parallel workstreams that DO communicate → agent team

---

### Axis 5 — Should it be distributed to other teams/repos?

| Answer | Recommendation                    |
| ------ | --------------------------------- |
| Yes    | Wrap everything in a **Plugin**   |
| No     | Keep as project-scoped primitives |

---

### Axis 6 — Is it a CI/CD pipeline or external script?

| Answer                                     | Sub-question | Recommendation                                                                                            |
| ------------------------------------------ | ------------ | --------------------------------------------------------------------------------------------------------- |
| Yes, fully autonomous                      | —            | **Headless mode** (`claude -p`) with `--permission-mode dontAsk`                                          |
| Yes, but needs human approval at key steps | —            | **Headless mode** + PreToolUse hook returning `"defer"` — pauses at tool call, resumes with `-p --resume` |
| No                                         | —            | Interactive skill or subagent                                                                             |

**`sandbox.failIfUnavailable: true`** — in security-critical CI, set this to exit immediately if
sandbox isolation isn't available rather than running unsandboxed.

---

### 🆕 Axis 7 — Does it need to run on a recurring schedule?

| Answer                              | Recommendation                                                                                                                                    |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yes, within an active session       | **`/loop`** — `/loop 5m check the deploy` runs a prompt or slash command on interval. `CLAUDE_CODE_DISABLE_CRON` stops all cron jobs mid-session. |
| Yes, as a persistent background job | **Cron scheduling tools** — available within a session for recurring prompts                                                                      |
| No                                  | Not applicable                                                                                                                                    |

**`/loop` use cases:** health checks, polling for CI status, periodic summarization, watch-and-react patterns.
**Limitation:** requires an active session — not a replacement for OS-level cron or CI schedulers.

---

## Composite recommendations

Most real setups combine primitives. Common combos:

| Goal                                                          | Primary                                                                 | Key reason for choice                                |
| ------------------------------------------------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------- |
| Workflow with verbose output (audits, scaffolding, long logs) | Skill with `context: fork`                                              | Output isolation — main session stays clean          |
| Workflow with side effects (deploy, send, delete)             | Skill with `disable-model-invocation: true`                             | Prevent autonomous triggering                        |
| Thin orchestration, short output, no side effects             | Slash command                                                           | Simpler, sufficient, model-invocable                 |
| Parallel expert review                                        | Skill (orchestrator) + subagents with `permissionMode: plan`            | Isolation per reviewer                               |
| Quality enforcement                                           | PostToolUse hook + PreToolUse hook                                      | Deterministic, not a suggestion                      |
| Targeted quality enforcement                                  | Hook with `if` field (e.g. `"if": "Bash(git push*)"`)                   | 🆕 Precise filtering, avoids unnecessary script runs |
| External service workflow                                     | MCP server + Skill wrapping orchestration                               | MCP provides tools, skill provides logic             |
| CI pipeline (fully autonomous)                                | Headless `claude -p` + `dontAsk` mode + hooks                           | No human present                                     |
| CI pipeline (human-in-the-loop)                               | Headless `claude -p` + PreToolUse hook returning `"defer"` + `--resume` | 🆕 Pause at key steps for approval                   |
| Codebase expert                                               | Subagent with `memory: project` + `permissionMode: plan`                | Persistent learning, read-only                       |
| Self-starting agent                                           | Subagent with `initialPrompt` + `--agent` flag                          | 🆕 Zero-interaction bootstrap                        |
| File-type-scoped guidance                                     | Skill or rule with `paths` field                                        | 🆕 Only loads when matching files touched            |
| Reactive environment                                          | `CwdChanged`/`FileChanged` hooks + `CLAUDE_ENV_FILE`                    | 🆕 Auto-reload env vars on file/dir changes          |
| Team distribution                                             | Plugin                                                                  | Single install for everything                        |
| Recurring in-session automation                               | `/loop` + slash command or skill as target                              | Schedule-driven                                      |

---

## Writer/Reviewer Separation — when to isolate context

Any workflow where **one phase produces output** and **a subsequent phase evaluates it** benefits
from context separation. Without it, Claude is biased toward output it just generated.

| Workflow                               | Separate? | Mechanism                                     |
| -------------------------------------- | --------- | --------------------------------------------- |
| Code review (writer ≠ reviewer)        | ✅ Yes    | Subagent reviewer, or separate `claude -p`    |
| TDD (test writer ≠ implementer)        | ✅ Yes    | Skill with `context: fork` for implementation |
| Security audit after implementation    | ✅ Yes    | Subagent with `permissionMode: plan`          |
| Migration validation                   | ✅ Yes    | Separate `claude -p` invocation               |
| Test generation after writing code     | ✅ Yes    | Separate session reads code cold              |
| Sequential build steps (no evaluation) | ❌ No     | Context continuity is valuable here           |
| Refactoring a single module            | ❌ No     | Continuity helps                              |

---

## Permission mode selection

| Mode                | Use when                                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `default`           | Learning, untrusted code, user wants to approve each action                                                                    |
| `acceptEdits`       | Fast iteration — auto-approve writes, still prompt for bash                                                                    |
| `plan`              | Read-only exploration, research agents, reviewers                                                                              |
| `bypassPermissions` | Isolated containers/VMs only — never in production                                                                             |
| `dontAsk`           | CI/CD headless — silently denies anything not whitelisted                                                                      |
| `auto`              | Interactive with classifier-based approval. 🆕 Cascades to ALL subagents — `permissionMode` in subagent frontmatter is ignored |

**Auto mode interaction with hooks:**

- 🆕 `PermissionDenied` hook fires after auto mode denials — return `{retry: true}` to let model retry
- Denied commands appear in `/permissions` → Recent tab for user retry

---

## Model selection guide

| Model      | Use for                                                                        |
| ---------- | ------------------------------------------------------------------------------ |
| `haiku`    | Simple subagents (Explore-like), high-volume batch, hook prompt/agent handlers |
| `sonnet`   | General work, most skills, most subagents                                      |
| `opus`     | Complex planning, security review, architecture decisions                      |
| `opusplan` | Planning phase Opus + execution phase Sonnet auto-switch                       |

Effort levels (`low`/`medium`/`high`/`max`) control thinking depth on Opus 4.6 and Sonnet 4.6.
Use `effort: low` on high-volume batch subagents to control cost.
Use `effort: max` for complex architectural decisions, security reviews, or TPP-level analysis.
