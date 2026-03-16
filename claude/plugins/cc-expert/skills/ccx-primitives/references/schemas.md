# Claude Code Primitive Schemas

> Source: claude-code-orchestration-guide.md (project knowledge) + session-fetched docs.
> Last manually verified: 2026-03-16.

---

## Table of contents

1. [Skill — SKILL.md](#1-skill--skillmd)
2. [Slash command — .claude/commands/*.md](#2-slash-command--claudecommands)
3. [Subagent — .claude/agents/*.md](#3-subagent--claudeagents)
4. [Rule — .claude/rules/*.md](#4-rule--clauderules)
5. [Global hooks — settings.json](#5-global-hooks--settingsjson)
6. [Output style — .claude/output-styles/*.md](#6-output-style--claudeoutput-styles)
7. [Plugin manifest — plugin.json](#7-plugin-manifest--pluginjson)
8. [Cross-primitive comparison](#8-cross-primitive-comparison)
9. [Common gotchas](#9-common-gotchas)

---

## 1. Skill — SKILL.md

**Locations (priority order):** managed > user (`~/.claude/skills/`) > project (`.claude/skills/`) > `--add-dir` directories (auto-loaded with live change detection) > nested `.claude/skills/` in subdirectories (monorepo support)

```yaml
---
name: my-skill                        # REQUIRED. lowercase + hyphens, max 64 chars → becomes /my-skill
description: "..."                     # REQUIRED. max 1024 chars — primary model discovery mechanism
disable-model-invocation: true         # optional. default false. true = only user can invoke via /name
user-invocable: false                  # optional. default true. false = only model can invoke
allowed-tools: Read, Grep, Glob        # optional. restricts tool surface. Comma-sep or YAML list.
context: fork                          # optional. runs in isolated subagent context (own context window)
agent: Explore                         # optional. Explore | Plan | general-purpose | <custom-agent-name>
model: sonnet                          # optional. sonnet | opus | haiku | opusplan | default
# effortLevel: low                     # optional. 🆕 low | medium | high  (max was removed)
argument-hint: "<topic>"               # optional. autocomplete hint shown after /skill-name in UI
hooks:                                 # optional. scoped to skill lifecycle, auto-cleaned when done
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
---
```

**String substitution variables** (in skill body):

| Variable | Description |
|---|---|
| `$ARGUMENTS` | Everything typed after `/skill-name` |
| `$1`, `$2`, ... | Positional arguments |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md. For plugin skills, this is the skill subdirectory, not the plugin root. |

**Special content prefixes** (in skill body):

| Prefix | Effect |
|---|---|
| `!` before backtick block | Executes bash before skill runs; output injected as context |
| `@` before path | Includes file contents |
| `ultrathink` anywhere | Enables extended thinking |

---

## 2. Slash command — .claude/commands/*.md

**Locations:** project (`.claude/commands/`) > user (`~/.claude/commands/`)
Single `.md` file only — no directories, no supporting files.

```yaml
---
description: "..."                     # REQUIRED. shown in / autocomplete menu
allowed-tools: Read, Grep, Glob        # optional. same syntax as skills
model: sonnet                          # optional. sonnet | opus | haiku | opusplan | default
---
```

**Fields NOT supported** (use skills for these):

| Field | Reason |
|---|---|
| `name` | Filename is the name |
| `context: fork` | No isolated subagent context |
| `agent` | No agent selection |
| `user-invocable` | Always user-invocable by definition |
| `disable-model-invocation` | 🆕 Cannot be controlled — model CAN now invoke commands via SlashCommand tool |
| `hooks` | No lifecycle hooks |

**🆕 SlashCommand tool — model-triggered invocation:**
Claude can now invoke slash commands programmatically via the `SlashCommand` tool, not just users.
This changes the previous guarantee that commands were user-only. Key implications:
- If you need to **prevent** model invocation → use a skill with `disable-model-invocation: true`
- If you **want** model invocation but prefer a lighter single-file format → a command now works
- Commands remain simpler to deploy (no directory, no supporting files) and are now viable as lightweight model-invocable building blocks

**Shared with skills:** `$ARGUMENTS`, `$1`, `$2` substitution; `!` (bash exec), `@` (file include), `ultrathink`.

---

## 3. Subagent — .claude/agents/*.md

**Locations (priority, highest wins on collision):** managed > CLI `--agents` > project (`.claude/agents/`) > user (`~/.claude/agents/`) > plugin

```yaml
---
name: code-reviewer                    # REQUIRED. identifier used for delegation
description: "..."                     # REQUIRED. model reads to decide when to delegate
tools: Read, Glob, Grep                # optional. comma-sep allowlist. Omit = inherits ALL tools incl. MCP
disallowedTools: Bash                  # optional. block specific tools
model: sonnet                          # optional. sonnet | opus | haiku | opusplan | default
permissionMode: default                # optional. default | acceptEdits | bypassPermissions | plan | dontAsk | ignore
maxTurns: 20                           # optional. limit agentic loop iterations
skills:                                # optional. inject full skill content at subagent startup
  - api-conventions
  - error-handling-patterns
memory: user                           # optional. user | project | local
isolation: worktree                    # optional. each invocation gets its own git worktree (auto-cleaned)
background: true                       # optional. always run as background task
hooks:                                 # optional. scoped to subagent lifecycle
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
mcpServers:                            # optional. MCP servers scoped to this subagent only
  github:
    type: http
    url: https://api.githubcopilot.com/mcp/
---
System prompt body goes here.
```

**Built-in agents:** `Explore` (Haiku, read-only), `Plan` (Sonnet, read-only), `general-purpose` (Sonnet, full tools).

**Key constraints:**
- Subagents CANNOT spawn other subagents
- Communication is one-way (summary returned to parent)
- `bypassPermissions` on parent cascades to ALL subagents, cannot be overridden
- Stop hooks in frontmatter auto-convert to SubagentStop
- 🆕 `memory: project` directory can be relocated via `autoMemoryDirectory` in settings.json — useful for shared/synced team memory

---

## 4. Rule — .claude/rules/*.md

**Locations:** user (`~/.claude/rules/`) > project (`.claude/rules/`)

> ⚠️ Rule files support exactly **one** frontmatter field. All others are invalid.

```yaml
---
paths:                                 # ONLY valid field. Glob patterns to scope when rule loads.
  - "src/api/**/*.ts"
  - "src/models/**/*.{ts,js}"
---
Rule body as plain Markdown.
```

When `paths` is **omitted**: rule loads unconditionally at session start (same as CLAUDE.md).
When `paths` is **set**: rule loads only when Claude reads files matching at least one pattern.

**Fields that are NOT valid for rules:**

| Field | Status | Source of confusion |
|---|---|---|
| `name` | ❌ Invalid | Borrowed from subagent schema |
| `description` | ❌ Invalid | Borrowed from subagent schema |
| `priority` | ❌ Invalid | Not documented anywhere |
| `globs` | ⚠️ Undocumented | Cursor equivalent; may work but not guaranteed |
| `alwaysApply` | ❌ Cursor-only | Confirmed non-functional (GitHub #16299) |
| `excludePaths` | ❌ Invalid | Only in AI-generated docs |

**Known parser quirk (GitHub #17204):** Quoted glob strings in YAML list format can fail to match; unquoted strings work reliably.

---

## 5. Global hooks — settings.json

Hooks live under the `"hooks"` key in any `settings.json` file (user, project, local, or managed).

### Top-level structure

```jsonc
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "regex-pattern",   // optional. regex against event-specific field (see below)
        "hooks": [                    // array of handlers — fire in parallel when matcher hits
          { "type": "command", "command": "..." },
          { "type": "http", "url": "..." }
        ]
      }
    ]
  }
}
```

### All 21 hook events

| Event | Matcher field | Blocks? |
|---|---|---|
| `PreToolUse` | `tool_name` | ✅ Yes |
| `PostToolUse` | `tool_name` | ❌ No (feedback only — `additionalContext`, `updatedMCPToolOutput`) |
| `PostToolUseFailure` | `tool_name` | ❌ No (feedback only — `additionalContext`) |
| `PermissionRequest` | `tool_name` | ✅ Yes |
| `UserPromptSubmit` | ignored | ✅ Yes |
| `Stop` | ignored | ✅ Yes (block = force continue) |
| `SubagentStop` | `agent_type` | ✅ Yes |
| `TaskCompleted` | ignored | ✅ Yes (exit code) |
| `TeammateIdle` | ignored | ✅ Yes (exit 2 = send feedback) |
| `ConfigChange` | `source` (user_settings/project_settings/local_settings/policy_settings/skills) | ✅ Yes (except policy) |
| `WorktreeCreate` | ignored | ✅ Yes (non-zero = fail) |
| `Elicitation` | ignored | ✅ Yes (exit 2 or `action: "decline"`) |
| `ElicitationResult` | ignored | ✅ Yes (exit 2 or `action: "decline"`) |
| `SessionStart` | `source` (startup/resume/clear/compact) | ❌ No |
| `SessionEnd` | `reason` (clear/logout/prompt_input_exit/bypass_permissions_disabled/other) | ❌ No |
| `InstructionsLoaded` | ignored | ❌ No (observability only) |
| `Notification` | `notification_type` (permission_prompt/idle_prompt/auth_success/elicitation_dialog) | ❌ No |
| `SubagentStart` | `agent_type` | ❌ No |
| `PreCompact` | `trigger` (manual/auto) | ❌ No |
| `PostCompact` | `trigger` (manual/auto) | ❌ No |
| `WorktreeRemove` | ignored | ❌ No |

### 4 handler types

**Common fields on all handlers:**

| Field | Description |
|---|---|
| `type` | **Required.** `"command"` \| `"http"` \| `"prompt"` \| `"agent"` |
| `timeout` | Seconds before cancellation (defaults vary by type) |
| `statusMessage` | Custom spinner text shown while running |
| `once` | Boolean. Fire once per session then remove (skills/slash commands only) |

#### `type: "command"`

```jsonc
{
  "type": "command",
  "command": "./scripts/lint.sh",    // REQUIRED. Receives event JSON on stdin.
  "timeout": 30,                     // default: 600s
  "async": false                     // optional. Run in background, non-blocking. Command-type only.
}
```

Exit codes: **0** = allow (stdout parsed as JSON), **2** = block (stderr → Claude, stdout ignored), **other** = non-blocking error.

#### `type: "http"`

```jsonc
{
  "type": "http",
  "url": "http://localhost:8080/hooks/validate",  // REQUIRED. POST with event JSON as body.
  "timeout": 30,                                   // default: 600s
  "headers": { "Authorization": "Bearer $MY_TOKEN" },
  "allowedEnvVars": ["MY_TOKEN"]                  // restricts which env vars can be interpolated
}
```

Non-2xx = non-blocking. To block: return 2xx with `{"decision": "block"}`.
Not supported for `SessionStart` events.

#### `type: "prompt"`

```jsonc
{
  "type": "prompt",
  "prompt": "Check if tasks are complete... $ARGUMENTS",  // REQUIRED. $ARGUMENTS = hook input JSON
  "model": "haiku",                                        // optional. default: fast model (Haiku)
  "timeout": 30                                            // default: 30s
}
```

Returns `{"decision": "approve"}` or `{"decision": "block", "reason": "..."}`.

#### `type: "agent"`

```jsonc
{
  "type": "agent",
  "prompt": "Verify the code compiles...",  // REQUIRED. System prompt for spawned subagent.
  "model": "haiku",                          // optional. default: fast model (Haiku)
  "timeout": 60                              // default: 60s. Subagent gets Read, Grep, Glob; max 50 turns.
}
```

Same `{"decision": "approve/block"}` response schema as prompt hooks.

### Hook security settings

| Key | Scope | Description |
|---|---|---|
| `disableAllHooks` | any | Disables all hooks. Managed-level only can disable managed hooks. |
| `allowManagedHooksOnly` | managed only | Blocks user/project/plugin hooks. Only managed hooks run. |
| `hookAllowedURLs` | any, merges | Restricts HTTP hook target URLs. Supports `*` wildcard. |
| `hookAllowedEnvVars` | any, merges | Restricts env var names for HTTP header interpolation. Effective set = **intersection** with handler's own `allowedEnvVars`. |
| 🆕 `autoMemoryDirectory` | any | Custom directory for auto-memory storage. Default is project-scoped. Useful for synced drives or shared team memory. |

### Environment variables available to hook commands

| Variable | Available in |
|---|---|
| `CLAUDE_PROJECT_DIR` | All hooks |
| `CLAUDE_SESSION_ID` | All hooks (v2.1.9+) |
| `CLAUDE_CODE_REMOTE` | All hooks (`"true"` in remote web environments) |
| `CLAUDE_ENV_FILE` | `SessionStart` only — write `export VAR=value` lines to persist vars |
| `CLAUDE_PLUGIN_ROOT` | Plugin hooks only |

---

## 6. Output style — .claude/output-styles/*.md

**Locations:** user (`~/.claude/output-styles/`) > project (`.claude/output-styles/`)

```yaml
---
name: My Custom Style          # REQUIRED. Shown in style picker
description: Brief description # REQUIRED. Shown in style picker
---
# Custom system prompt content
# This REPLACES Claude Code's default engineering system prompt entirely.
```

**Key distinction:** Output styles replace the default system prompt. CLAUDE.md and
`--append-system-prompt` ADD to it. Skills are task-specific; output styles are always-on.

---

## 7. Plugin manifest — plugin.json

Located at `.claude-plugin/plugin.json` in the plugin root.

```jsonc
{
  "name": "my-plugin",           // REQUIRED. Becomes namespace prefix (skills → /my-plugin:skill-name)
  "version": "1.2.0",            // REQUIRED. Semantic version for marketplace updates.
  "description": "...",
  "author": { "name": "...", "email": "...", "url": "..." },
  "homepage": "...",
  "repository": "...",
  "license": "MIT",
  "keywords": ["..."],
  "commands": ["./custom/commands/special.md"],  // default: commands/
  "agents": "./custom/agents/",                   // default: agents/
  "skills": "./custom/skills/",                   // default: skills/
  "hooks": "./config/hooks.json",                 // default: hooks/hooks.json
  "mcpServers": "./mcp-config.json",              // default: .mcp.json
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json",
  "settings": { "agent": "security-reviewer" }   // default config applied when plugin enabled
}
```

---

## 8. Cross-primitive comparison

**The skill vs command decision in one line:** Does it generate verbose output? → `context: fork` on a skill. Everything else → slash command.

| Feature | Skill | Command | Subagent | Rule | Hook |
|---|---|---|---|---|---|
| `name` field | ✅ required | ❌ (filename) | ✅ required | ❌ invalid | — |
| `description` field | ✅ required | ✅ required | ✅ required | ❌ invalid | — |
| `model` field | ✅ | ✅ | ✅ | ❌ | ✅ (prompt/agent types) |
| `allowed-tools` / `tools` | ✅ | ✅ | ✅ | ❌ | — |
| `hooks` in frontmatter | ✅ | ❌ | ✅ | ❌ | N/A |
| `context: fork` ⭐ | ✅ | ❌ **primary reason to use skill over command** | — | ❌ | — |
| `permissionMode` | ❌ | ❌ | ✅ | ❌ | — |
| `memory` | ❌ | ❌ | ✅ | ❌ | — |
| `paths` (scoping) | ❌ | ❌ | ❌ | ✅ only field | — |
| `disable-model-invocation` | ✅ | ❌ | — | ❌ | — |
| User can invoke | ✅ | ✅ always | via delegation | — | — |
| Model can invoke | ✅ (unless disabled) | 🆕 ✅ via SlashCommand tool (uncontrollable) | ✅ | — | auto |
| Isolated context window | ✅ `context: fork` | ❌ | ✅ always | — | ✅ always |
| Directories + files | ✅ | ❌ | ✅ | ❌ | — |
| `$ARGUMENTS` substitution | ✅ | ✅ | ❌ | ❌ | ✅ (prompt/agent) |

---

## 9. Common gotchas

### Rules
- `paths` uses glob syntax; `**` matches recursively, `*` matches within one directory level
- Unquoted glob values in YAML are more reliable than quoted ones (parser quirk #17204)
- Conditional path rules still load the rule names/headers globally; only body is deferred

### Skills
- `disable-model-invocation: true` is **mandatory** for anything with side effects (deploy, send, delete)
- `context: fork` means only the summary returns to the main session — the full investigation log stays isolated
- `allowed-tools` on a skill restricts that invocation only; it does not restrict MCP unless explicitly listed

### Subagents
- Omitting `tools` gives the subagent **all tools including MCP** — always be explicit
- `permissionMode: bypassPermissions` on the parent silently cascades — you cannot override it per-subagent
- `memory: project` persists at `~/.claude/projects/<project>/memory/agents/<name>/`

### Hooks
- Exit 0 + JSON on stdout OR exit 2 + plain text on stderr — **never both**. Exit 2 ignores stdout entirely.
- `PostToolUse` JSON fields `decision`/`reason` belong inside `hookSpecificOutput`, not at top level
- `Stop` hook: always check `stop_hook_active` field — if true, approve unconditionally to avoid infinite loop
- `async: true` is **command-type only** — not supported on http, prompt, or agent handlers
- HTTP hooks are not supported for `SessionStart` events
- `CLAUDE_ENV_FILE` is `SessionStart`-only — writing env vars elsewhere has no effect

### Slash commands vs Skills

**The single most important question: will it generate verbose output?**
- Yes → Skill with `context: fork` — the output stays isolated, only the summary returns to your session
- No → Slash command is sufficient

**Secondary reasons to choose a skill over a command:**
- Need to prevent model invocation entirely (side effects) → Skill with `disable-model-invocation: true`
- Need model-only invocation (background knowledge) → Skill with `user-invocable: false`
- Need lifecycle hooks, supporting files, or agent selection → Skill

**Everything else → Slash command.** Lighter, no directories, now model-invocable via SlashCommand tool.

A thin orchestration body that just sequences steps and delegates to subagents? That's a command — unless those subagents return verbose output that would bloat your session, in which case `context: fork` on a skill is the right call.

### 🆕 Bash permission rules — redirect matching
- `Bash(python:*)` now also matches `python script.py > output.txt` — output redirections are covered by the rule
- Previously, redirect variants could bypass pattern-based allow/deny rules — this is now fixed
- Update any existing deny rules that were written with workarounds for this gap

### 🆕 Settings — autoMemoryDirectory
- `"autoMemoryDirectory": "/path/to/dir"` — configure a custom directory for auto-memory storage
- Useful when you want memory files stored outside the default location (e.g., a synced drive, a shared team directory)

### 🆕 /context command — actionable optimization suggestions
- `/context` now identifies context-heavy tools, memory bloat, and capacity warnings
- Includes specific optimization tips (e.g., "use context: fork for this skill", "this rule is loading too early")
- Use it proactively when sessions feel slow or context is filling up

### 🆕 Read tool — PDF pages parameter
- `pages: "1-5"` reads specific page ranges from PDFs instead of the full document
- Large PDFs (>10 pages) now return a lightweight reference when @-mentioned instead of being inlined
- Update `allowed-tools` guidance: PDF-heavy skills benefit from scoped page reads

### 🆕 Skills — hot-reload
- Skills created or modified in `~/.claude/skills/` or `.claude/skills/` are now immediately available without restarting the session
- No restart needed after installing or editing a skill during development

### 🆕 Agent tool — model parameter restored
- `model` parameter on the Agent tool works again for per-invocation model overrides
- Subagent `model` field in frontmatter sets the default; Agent tool `model` overrides it per-call

### 🆕 Hook events — InstructionsLoaded (observability)
- Fires when CLAUDE.md or `.claude/rules/*.md` files are loaded
- Input fields: `file_path`, `memory_type` (User/Project/Local/Managed), `load_reason` (session_start/nested_traversal/path_glob_match/include), `globs`, `trigger_file_path`, `parent_file_path`
- Non-blocking, no output schema — useful for logging/auditing which context files load and why

### 🆕 Hook events — PostCompact
- Fires after context compaction completes (manual or auto)
- Input fields: `trigger` (manual/auto), `compact_summary` (the generated conversation summary)
- Non-blocking — useful for logging compaction events or persisting summaries

### 🆕 Hook events — Elicitation & ElicitationResult
- `Elicitation`: fires when an MCP server requests user input (form or auth URL)
- `ElicitationResult`: fires after user responds to the elicitation
- Input fields: `mcp_server_name`, `message`, `mode` (form/url), `url`, `elicitation_id`, `requested_schema`, `action` (accept/decline/cancel), `content`
- Both can block: exit 2 or `hookSpecificOutput.action: "decline"` to reject
- Use case: auto-approve known MCP servers, log auth flows, enforce MCP interaction policies

### 🆕 Hook events — Setup deprecated
- The `Setup` event no longer appears in official docs as of March 2026
- Likely replaced by `InstructionsLoaded` for observability and `SessionStart` for initialization
- Existing `Setup` hooks should be migrated

### 🆕 PostToolUse/PostToolUseFailure — additional output fields
- `updatedMCPToolOutput`: in PostToolUse `hookSpecificOutput`, allows rewriting MCP tool output before Claude sees it
- `is_interrupt`: boolean field in PostToolUseFailure input, indicates whether failure was due to user interrupt

### 🆕 Skills — `--add-dir` skill loading
- Skills in `.claude/skills/` within directories added via `--add-dir` are auto-loaded with live change detection
- CLAUDE.md files from `--add-dir` are NOT loaded by default — set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to enable

### 🆕 Environment variables — additional
- `SLASH_COMMAND_TOOL_CHAR_BUDGET`: override skill description budget (default: 2% of context window, fallback 16K chars)
- `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`: timeout for SessionEnd hooks (default 1500ms)
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`: enable loading CLAUDE.md from `--add-dir` directories
