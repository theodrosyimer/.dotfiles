# Workflow Patterns — Match Reference

18 concrete patterns. Updated April 2026 (v2.1.89).
Use these to match a user's described automation to the closest existing pattern.

---

## Pattern 1 — Gated Deployment Skill

**Trigger signals:** User mentions deploy, release, CI gate, staging/production, side effects that
must not auto-run.

**Primitives:** Skill (`disable-model-invocation: true`, `context: fork`) + PreToolUse hook on Bash

**Key design decisions:**
- `disable-model-invocation: true` — prevents autonomous deployment
- `context: fork` — deployment logs don't bloat main session
- Hook validates every shell command before execution
- `allowed-tools` prevents Write/Edit — read and execute only
- `$1` captures environment argument (`/deploy staging`)

---

## Pattern 2 — Parallel Code Review Pipeline

**Trigger signals:** User wants thorough review, multiple perspectives, security + perf + style,
wants specialized reviewers.

**Primitives:** Multiple subagents (one per domain) + orchestrating skill

**Key design decisions:**
- Each reviewer: focused system prompt, `permissionMode: plan`, `tools: Read, Grep, Glob`
- `memory: project` — reviewers accumulate codebase patterns over time
- Orchestrating skill spawns them in parallel, aggregates findings by severity
- Fresh subagent context = no bias from implementation (Writer/Reviewer Separation)
- 🆕 **SlashCommand opportunity:** lightweight pre-review steps (e.g., "summarize the diff",
  "list changed files") can now be slash commands the orchestrating skill invokes via the
  SlashCommand tool — no subagent overhead for read-only single-step operations

---

## Pattern 3 — Deterministic Quality Gates

**Trigger signals:** User wants guarantees not suggestions. "Never do X", "always format after
edit", "make sure tasks are complete before stopping".

**Primitives:** Hooks only (PreToolUse + PostToolUse + Stop)

**Key design decisions:**
- PreToolUse: block sensitive file writes deterministically
- PostToolUse on Write|Edit: auto-format changed files
- Stop hook (prompt type): verify completeness before Claude declares done
- Stop hook MUST check `stop_hook_active` to avoid infinite loop
- 🆕 **`if` field for targeted enforcement:** use `"if": "Bash(git push*)"` to scope hooks to
  specific command patterns — avoids running validation scripts on every Bash command when you
  only care about specific ones. The `if` field handles compound commands (`ls && git push`)
  and env-prefixed commands (`FOO=bar git push`) correctly since v2.1.89.
- **SlashCommand opportunity:** PostToolUse hooks can invoke a slash command for
  richer post-edit checks — previously required a full external script or subagent

---

## Pattern 4 — Issue-to-PR Skill (End-to-End Workflow)

**Trigger signals:** User wants a single command that spans understand → implement → verify → ship.
Often involves GitHub or issue trackers.

**Primitives:** Skill + MCP (GitHub) + phased instructions

**Key design decisions:**
- `disable-model-invocation: true` — user decides when to fix issues
- MCP listed in `allowed-tools` for GitHub access
- Phased body prevents jumping to implementation before understanding
- Explicit test/lint step before PR creation
- 🆕 **SlashCommand opportunity:** discrete read-only phases (e.g., "summarize issue",
  "list affected files", "format commit message") can be extracted into slash commands that
  the skill invokes via SlashCommand tool — keeps the main skill body clean and makes
  individual phases independently reusable

---

## Pattern 5 — Background Research Agent with Persistent Memory

**Trigger signals:** User wants an agent that gets smarter over time, learns codebase patterns,
answers architecture questions without re-discovering things every session.

**Primitives:** Subagent with `memory: project` + `permissionMode: plan`

**Key design decisions:**
- `memory: project` — persists at `.claude/agent-memory/<n>/` (committable to version control)
- `permissionMode: plan` — pure investigation, never modifies code
- `maxTurns: 50` — room for deep exploration
- System prompt instructs agent to update memory after each investigation
- 🆕 **Self-starting variant:** add `initialPrompt: "/setup and explore the codebase"` + use with
  `claude --agent <name>` for zero-interaction bootstrap. The initial prompt is auto-submitted
  as the first user turn, so the agent starts working immediately without waiting for input.

---

## Pattern 6 — CI/CD Pipeline with Headless Mode

**Trigger signals:** User wants to run Claude from GitHub Actions, shell scripts, cron jobs,
no interactive terminal.

**Primitives:** Headless `claude -p` + `--output-format json` + `--resume` for multi-step

**Key design decisions:**
- `--resume` chains multi-step workflows via session IDs
- `--output-format json` enables `jq` parsing
- `--permission-mode plan` for read-only review steps
- `--permission-mode acceptEdits` for write steps
- `--allowedTools` scopes permissions per step
- `xargs -P N` for parallel file processing
- 🆕 **Human-in-the-loop via `defer`:** PreToolUse hook returns `{"permissionDecision": "defer"}`
  to pause the headless session at a specific tool call. Resume with `claude -p --resume` after
  human review. Use for deployment approval gates, sensitive data access, or production changes.
- 🆕 **`sandbox.failIfUnavailable: true`** — exit immediately if sandbox isn't available rather
  than running unsandboxed. Critical for CI environments that require isolation.
- **SlashCommand opportunity:** discrete pipeline steps that don't need isolation can be
  slash commands invoked within a headless session — reusable across CI pipelines

---

## Pattern 7 — Agent Teams for Complex Feature Development

**Trigger signals:** User wants sustained parallel work, agents sharing intermediate findings,
workers challenging each other's approaches. Token cost is acceptable.

**Primitives:** Agent teams (experimental: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

**Key design decisions:**
- Only use when workers genuinely need to communicate — otherwise use subagents
- Each teammate gets its own worktree
- 3-4x token overhead — justify with parallelism benefit
- Graduation path: subagents → agent teams when context limits hit or communication needed

**When NOT to use:**
- Sequential tasks (B depends entirely on A) → subagent chaining
- Same-file edits → conflict
- Simple parallelism with no cross-communication → parallel subagents
- Token budget concern → parallel subagents

---

## Pattern 8 — MCP + Skills Composition

**Trigger signals:** User needs Claude to work with external services (GitHub, Sentry, DB, Slack)
as part of a structured workflow.

**Primitives:** MCP server in `.mcp.json` + Skill wrapping the orchestration logic

**Key design decisions:**
- MCP provides the tools; skill provides the workflow structure
- `allowed-tools` explicitly lists which MCP servers the skill can use (`mcp__sentry`, etc.)
- Skill stops before implementation — user confirms before state changes
- 🆕 **SlashCommand opportunity:** repeated read-only lookups (e.g., "get issue details",
  "format stack trace") can be slash commands the orchestrating skill invokes — avoids
  re-describing the same sub-task inline every time and makes them reusable across skills

---

## Pattern 9 — Plugin Packaging

**Trigger signals:** User has a working set of skills/agents/hooks and wants to share across
repos or with their team.

**Primitives:** Plugin manifest (`plugin.json`) wrapping all other primitives

**Key design decisions:**
- Skills namespaced as `/plugin-name:skill-name`
- Single install command gives team all skills, agents, hooks, and MCP connections
- `version` field required for marketplace updates

---

## Pattern 10 — Plan-Then-Execute (Interactive Permission Mode Workflow)

**Trigger signals:** User has a complex feature touching many files, wants to review the approach
before any edits happen, wants checkpoints.

**Primitives:** Permission mode cycling (`plan` → review → `acceptEdits`) + `Ctrl+G` plan editing

**Key design decisions:**
- `plan` mode is a hard constraint — Claude physically cannot edit files
- 🆕 `/plan fix the auth bug` — optional description argument enters plan mode and immediately starts on that goal (no separate prompt needed)
- `Shift+Tab` cycles modes without restart
- `acceptEdits` eliminates file-by-file approval during execution
- Headless equivalent: first `claude -p --permission-mode plan`, then `--resume --permission-mode acceptEdits`
- Subagent variant: `permissionMode: plan` on research agent + separate `permissionMode: acceptEdits` execution agent

---

## 🆕 Pattern 12 — Recurring In-Session Automation (`/loop` + cron)

**Trigger signals:** User wants something to run periodically — "check every 5 minutes", "poll
until CI passes", "summarize what changed every hour", "watch for errors and alert me".

**Primitives:** `/loop` command + slash command or skill as the recurring target

**Key design decisions:**
- `/loop 5m check the deploy` — runs a prompt or slash command on a recurring interval
- `/loop 30s run tests` — tight polling loop for watch-and-react patterns
- `CLAUDE_CODE_DISABLE_CRON` env var stops all cron/loop jobs mid-session immediately
- Target can be a slash command (lightweight) or a skill (if isolation or tool restrictions needed)
- Requires an active session — not a replacement for OS-level cron or CI schedulers

**Good use cases:** CI status polling, periodic health checks, deploy monitoring, session-scoped
watch patterns, recurring summarization of logs or metrics.

**When NOT to use:** persistent background jobs that must survive session end → use OS cron,
GitHub Actions schedule, or an external scheduler calling `claude -p`.

---

## 🆕 Pattern 13 — Slash Command as Lightweight Model-Invocable Building Block

**Trigger signals:** User wants a simple, single-file workflow that Claude can invoke
autonomously — but doesn't need isolation, hooks, lifecycle control, or side-effect protection.

**Primitives:** Slash command (single `.md` file) — now model-invocable via SlashCommand tool

**Key design decisions:**
- 🆕 Claude can now invoke slash commands programmatically via the SlashCommand tool — not just users
- Use when: workflow is simple, single-file is sufficient, you actively WANT model to invoke it
- Do NOT use when: workflow has side effects (deploys, sends, deletes) — you cannot set
  `disable-model-invocation` on commands. Use a skill with `disable-model-invocation: true` instead.
- Commands are lighter than skills — no directory, no supporting files, no frontmatter complexity
- Good for: formatting helpers, quick lookups, boilerplate generators, read-only analysis steps

**The key distinction from skills:**

| Need | Use |
|---|---|
| Model-invocable, simple, no side effects | Slash command |
| Model-invocable, needs isolation/hooks/tools | Skill |
| Must NEVER be model-invoked | Skill with `disable-model-invocation: true` |

---

## 🆕 Pattern 14 — Reactive Environment Hooks

**Trigger signals:** User wants env vars reloaded when `.env` changes, config refreshed when
files change, validation triggered when working directory changes.

**Primitives:** `CwdChanged` + `FileChanged` hooks with `CLAUDE_ENV_FILE`

**Key design decisions:**
- `FileChanged` matcher is `filename` (basename) — e.g., `.env`, `package.json`, `tsconfig.json`
- Both events support `CLAUDE_ENV_FILE` — write `export VAR=value` lines to persist env vars
- Non-blocking — environment updates happen silently
- Use `CwdChanged` for directory-aware setup (e.g., switching Node versions based on `.nvmrc`)
- Use `FileChanged` for file-aware reactions (e.g., re-run `pnpm install` when `package.json` changes)

**Example — auto-reload .env:**
```json
{
  "hooks": {
    "FileChanged": [
      {
        "matcher": ".env",
        "hooks": [
          { "type": "command", "command": "./scripts/reload-env.sh" }
        ]
      }
    ]
  }
}
```

**When NOT to use:** For enforcing rules (use PreToolUse hooks instead). `FileChanged` is
observational — it reacts to changes, it doesn't gate them.

---

## 🆕 Pattern 15 — Conditional Hook Enforcement

**Trigger signals:** User wants to validate only specific commands within a broad matcher —
"block git push but allow git status", "lint only .ts files after edit", "validate only rm commands".

**Primitives:** Hook with `if` field for pattern-level pre-filtering

**Key design decisions:**
- `matcher` selects the tool (e.g., `"Bash"`), `if` narrows to specific patterns (e.g., `"Bash(git push*)"`)
- `if` uses permission rule syntax — same format as `permissions.allow`/`permissions.deny`
- Avoids running validation scripts unnecessarily — pre-filter before script invocation
- Handles compound commands (`ls && git push`) and env-prefixed commands (`FOO=bar git push`) since v2.1.89
- Cannot use OR syntax — one `if` per handler. For multiple patterns, use multiple handler entries.

**Example — block only force push, allow other git commands:**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git push*)",
            "command": "./scripts/block-force-push.sh"
          }
        ]
      }
    ]
  }
}
```

**When NOT to use:** When you need to inspect ALL commands of a type (e.g., a modern-CLI
preference checker that suggests `fd` over `find`, `rg` over `grep` for any command).

---

## 🆕 Pattern 16 — Headless Approval Gates

**Trigger signals:** User wants CI pipeline with human approval at critical steps — "pause before
deploying", "wait for review before merging", "human-in-the-loop for production changes".

**Primitives:** PreToolUse hook returning `{"permissionDecision": "defer"}` + `claude -p --resume`

**Key design decisions:**
- Hook returns `"defer"` on the tool call that needs approval (e.g., a Bash deploy command)
- Session pauses — no further tool calls until resumed
- Human reviews the pending action, then runs `claude -p --resume` to continue
- Combines with `if` field to only defer specific commands (e.g., `"if": "Bash(deploy *)"`)
- The deferred tool input is preserved — `--resume` re-evaluates the hook

**Example CI workflow:**
```bash
# Step 1: implement and test (autonomous)
SESSION=$(claude -p "Fix bug #123 and run tests" --output-format json | jq -r '.session_id')

# Step 2: hook defers on git push → session pauses
# Human reviews changes, then:
claude -p --resume "$SESSION"   # hook re-evaluates, allows push
```

**When NOT to use:** Interactive sessions (use permission prompts). Fully autonomous CI
(use `dontAsk` + allow rules).

---

## 🆕 Pattern 17 — Self-Starting Agent

**Trigger signals:** User wants an agent that bootstraps itself without user input — "zero-touch
setup", "agent starts working immediately", "run skills on startup".

**Primitives:** Subagent with `initialPrompt` + `--agent` flag or `agent` setting

**Key design decisions:**
- `initialPrompt` is auto-submitted as the first user turn when agent runs as main session agent
- Commands and skills in the prompt are processed (e.g., `/setup`, `/init`)
- Prepended to any user-provided prompt — both run in sequence
- Only takes effect with `--agent <name>` or `agent` setting — ignored when spawned as subagent
- Combine with `memory: project` for agents that build up knowledge across sessions

**Example — self-bootstrapping codebase expert:**
```yaml
---
name: codebase-expert
description: Expert on this codebase, bootstraps on first run
initialPrompt: "Read CLAUDE.md, explore the directory structure, and save key findings to your memory."
memory: project
permissionMode: plan
model: sonnet
tools: Read, Grep, Glob
---
You are a codebase expert. Use your agent memory to accumulate knowledge.
```

**When NOT to use:** Subagents spawned by other agents (initialPrompt is ignored). Skills
(use `!` command blocks for pre-execution instead).

---

## 🆕 Pattern 18 — Context-Scoped Skills

**Trigger signals:** User has guidance that only applies to specific file types — "API conventions
for .ts files", "React patterns for .tsx", "testing rules for .test.ts files".

**Primitives:** Skill with `paths` field for auto-activation scoping

**Key design decisions:**
- `paths` accepts comma-separated string or YAML list of glob patterns
- Skill auto-activates only when Claude works with files matching the patterns
- Reduces context bloat — description still listed (capped at 250 chars), but full content only
  loads when relevant files are touched
- Same glob syntax as `.claude/rules/` `paths` field
- Combine with rules: use rules for short constraints, skills for detailed workflow guidance

**Example — API-specific conventions:**
```yaml
---
name: api-conventions
description: API design patterns for REST endpoints. Use when writing or reviewing API handlers.
paths:
  - "src/api/**/*.ts"
  - "src/handlers/**/*.ts"
---
When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats using ProblemDetails
- Include request validation with Zod schemas at the boundary
```

**When NOT to use:** Universal conventions that apply to all files (use CLAUDE.md or unconditional
rules). Workflows triggered by user command (use `disable-model-invocation: true` instead of
path scoping).

---

## Pattern 11 — Locked-Down CI Runner (Defense-in-Depth Headless Execution)

**Trigger signals:** User is running Claude in CI with no human present, needs full autonomy AND
maximum security, worried about prompt injection from malicious PRs.

**Primitives:** Three layers: Permission rules (`dontAsk` + whitelist) + Sandbox + Hooks

**Key design decisions:**
- `dontAsk` mode: silently denies anything not whitelisted — no hanging prompts in CI
- Deny list blocks dangerous patterns even if allow list later broadens
- `mcp__*` fully blocked — CI shouldn't hit external services through Claude
- Sandbox: `allowUnsandboxedCommands: false` disables escape hatch
- `allowUnixSockets: false` blocks Docker socket exploitation
- 🆕 `sandbox.failIfUnavailable: true` — exit immediately if sandbox unavailable
- Hook: validate command semantics (not just patterns), check file contents post-edit
- 🆕 Use `if` field on hooks for precise command filtering (e.g., `"if": "Bash(rm *)"`) —
  avoids running heavyweight validation scripts on every Bash command
- 🆕 `PermissionDenied` hook: log or alert when auto mode denies operations in CI — useful for
  post-run audit of what was blocked and why
- Stop hook verifies completeness before Claude declares done
