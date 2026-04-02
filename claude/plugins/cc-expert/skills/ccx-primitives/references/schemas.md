# Claude Code Primitive Schemas

> Source: official docs (code.claude.com) + CHANGELOG.md + session-fetched docs.
> Last manually verified: 2026-04-01 (v2.1.89).

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
name: my-skill                         # optional. lowercase + hyphens, max 64 chars → becomes /my-skill. Defaults to directory name if omitted.
description: "..."                     # recommended. max 1024 chars — primary model discovery mechanism. Falls back to first paragraph if omitted.
disable-model-invocation: true         # optional. default false. true = only user can invoke via /name
user-invocable: false                  # optional. default true. false = only model can invoke
allowed-tools: Read, Grep, Glob        # optional. restricts tool surface. Comma-sep or YAML list.
context: fork                          # optional. runs in isolated subagent context (own context window)
agent: Explore                         # optional. Explore | Plan | general-purpose | <custom-agent-name>
model: opus                            # optional. sonnet | opus | haiku | opusplan | full model ID (e.g. claude-opus-4-6)
effort: low                            # optional. low | medium | high | max (Opus 4.6 only). Overrides session effort.
argument-hint: "<topic>"               # optional. autocomplete hint shown after /skill-name in UI
paths:                                 # optional. 🆕 glob patterns limiting when skill auto-activates.
  - "src/api/**/*.ts"                  #   Comma-sep string or YAML list. Same format as rule paths.
shell: bash                            # optional. 🆕 bash (default) | powershell. Shell for !`cmd` blocks.
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
| `$ARGUMENTS[N]` | Access a specific argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` (`$0` = first arg, `$1` = second) |
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
model: opus                          # optional. sonnet | opus | haiku | opusplan | full model ID (e.g. claude-opus-4-6)
effort: low                            # optional. low | medium | high | max (Opus 4.6 only). Added in v2.1.80.
---
```

**Fields NOT supported** (use skills for these):

| Field | Reason |
|---|---|
| `name` | Filename is the name |
| `context: fork` | No isolated subagent context |
| `agent` | No agent selection |
| `user-invocable` | Always user-invocable by definition |
| `disable-model-invocation` | Cannot be controlled — model CAN invoke commands via SlashCommand tool |
| `hooks` | No lifecycle hooks |
| `paths` | No path-scoped activation (use skills with `paths`) |
| `shell` | No shell selection (use skills with `shell`) |

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
model: opus                          # optional. sonnet | opus | haiku | opusplan | full model ID (e.g. claude-opus-4-6) | inherit. Default: inherit (uses parent model)
effort: low                            # optional. low | medium | high | max (Opus 4.6 only). Overrides session effort.
permissionMode: default                # optional. default | acceptEdits | bypassPermissions | plan | dontAsk
maxTurns: 20                           # optional. limit agentic loop iterations
initialPrompt: "/setup and begin"      # optional. 🆕 auto-submitted as first user turn when used as --agent or `agent` setting. Commands/skills processed.
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

**Built-in agents:** `Explore` (Haiku, read-only), `Plan` (inherits model, read-only), `general-purpose` (inherits model, full tools), `Bash` (inherits, terminal commands), `statusline-setup` (Sonnet), `Claude Code Guide` (Haiku).

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

### All 25 hook events

| Event | Matcher field | Blocks? |
|---|---|---|
| `PreToolUse` | `tool_name` | ✅ Yes |
| `PostToolUse` | `tool_name` | ❌ No (feedback only — `additionalContext`, `updatedMCPToolOutput`) |
| `PostToolUseFailure` | `tool_name` | ❌ No (feedback only — `additionalContext`) |
| `PermissionRequest` | `tool_name` | ✅ Yes |
| `UserPromptSubmit` | ignored | ✅ Yes |
| `Stop` | ignored | ✅ Yes (block = force continue) |
| `SubagentStop` | `agent_type` | ✅ Yes |
| `TaskCreated` | ignored | 🆕 ✅ Yes (exit 2 = rolls back task creation) |
| `TaskCompleted` | ignored | ✅ Yes (exit code) |
| `TeammateIdle` | ignored | ✅ Yes (exit 2 = send feedback) |
| `ConfigChange` | `source` (user_settings/project_settings/local_settings/policy_settings/skills) | ✅ Yes (except policy) |
| `WorktreeCreate` | ignored | ✅ Yes (non-zero = fail) |
| `Elicitation` | ignored | ✅ Yes (exit 2 or `action: "decline"`) |
| `ElicitationResult` | ignored | ✅ Yes (exit 2 or `action: "decline"`) |
| `PermissionDenied` | `tool_name` | 🆕 ❌ No (return `{retry: true}` to retry) |
| `SessionStart` | `source` (startup/resume/clear/compact) | ❌ No |
| `SessionEnd` | `reason` (clear/resume/logout/prompt_input_exit/bypass_permissions_disabled/other) | ❌ No |
| `InstructionsLoaded` | ignored | ❌ No (observability only) |
| `Notification` | `notification_type` (permission_prompt/idle_prompt/auth_success/elicitation_dialog) | ❌ No |
| `SubagentStart` | `agent_type` | ❌ No |
| 🆕 `CwdChanged` | ignored | ❌ No (`CLAUDE_ENV_FILE` available) |
| 🆕 `FileChanged` | `filename` (basename, e.g. `.env`, `package.json`) | ❌ No (`CLAUDE_ENV_FILE` available) |
| `PreCompact` | `trigger` (manual/auto) | ❌ No |
| `PostCompact` | `trigger` (manual/auto) | ❌ No |
| `WorktreeRemove` | ignored | ❌ No |
| `StopFailure` | `error` (rate_limit/authentication_failed/billing_error/invalid_request/server_error/max_output_tokens/unknown) | ❌ No |

### 4 handler types

**Common fields on all handlers:**

| Field | Description |
|---|---|
| `type` | **Required.** `"command"` \| `"http"` \| `"prompt"` \| `"agent"` |
| `if` | 🆕 Optional. Permission rule syntax for conditional filtering (e.g. `"Bash(git *)"`, `"Edit(*.ts)"`). More granular than `matcher`. |
| `timeout` | Seconds before cancellation (defaults vary by type) |
| `statusMessage` | Custom spinner text shown while running |
| `once` | Boolean. Fire once per session then remove. **Skills only** — not supported on agents. |

#### `type: "command"`

```jsonc
{
  "type": "command",
  "command": "./scripts/lint.sh",    // REQUIRED. Receives event JSON on stdin.
  "timeout": 30,                     // default: 600s
  "async": false,                    // optional. Run in background, non-blocking. Command-type only.
  "shell": "bash"                    // 🆕 optional. "bash" (default) | "powershell". Command-type only.
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

Returns `{"ok": true}` or `{"ok": false, "reason": "..."}`.

#### `type: "agent"`

```jsonc
{
  "type": "agent",
  "prompt": "Verify the code compiles...",  // REQUIRED. System prompt for spawned subagent.
  "model": "haiku",                          // optional. default: fast model (Haiku)
  "timeout": 60                              // default: 60s. Subagent gets Read, Grep, Glob; max 50 turns.
}
```

Same `{"ok": true/false}` response schema as prompt hooks.

> **Known issue (v2.1.89):** `type: "agent"` consistently errors on `PostToolUse` events despite
> docs listing it as supported. `type: "prompt"` works correctly on `PostToolUse`. Use
> `type: "prompt"` for PostToolUse LLM-based evaluation, `type: "agent"` for `Stop`/`PreToolUse`
> where it's been confirmed to work. This may be fixed in a future release — re-test after
> upgrades.

### Hook response formats by event (command/http hooks)

Each event uses a different JSON structure for its response. Prompt/agent hooks use `{"ok": true/false}` uniformly.

#### PreToolUse — `hookSpecificOutput.permissionDecision`

```jsonc
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",     // "allow" | "deny" | "ask" | "defer"
    "permissionDecisionReason": "...", // shown to user (allow/ask) or Claude (deny)
    "updatedInput": { "command": "modified" },  // optional: rewrite tool args
    "additionalContext": "..."         // optional: added to Claude's context
  }
}
```

Top-level `decision`/`reason` deprecated for PreToolUse. Old `"approve"`→`"allow"`, `"block"`→`"deny"`.

#### PostToolUse / Stop / SubagentStop — top-level `decision`

```jsonc
{
  "decision": "block",                // "block" only — omit to allow
  "reason": "shown to Claude",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "...",        // optional: context for Claude
    "updatedMCPToolOutput": "..."      // optional: rewrite MCP tool output (PostToolUse only)
  }
}
```

#### PermissionRequest — `hookSpecificOutput.decision.behavior`

```jsonc
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",            // "allow" | "deny"
      "updatedInput": { "command": "modified" },  // optional (allow only)
      "updatedPermissions": [...],     // optional: add/remove rules, set mode
      "message": "reason for deny"     // optional (deny only)
    }
  }
}
```

#### PermissionDenied — `hookSpecificOutput.retry`

```jsonc
{ "hookSpecificOutput": { "hookEventName": "PermissionDenied", "retry": true } }
```

#### UserPromptSubmit — top-level `decision`

```jsonc
{ "decision": "block", "reason": "...", "hookSpecificOutput": { "additionalContext": "..." } }
```

#### Universal fields (all events)

```jsonc
{
  "continue": false,         // stops Claude entirely (overrides event-specific decisions)
  "stopReason": "message",   // shown to user when continue: false
  "suppressOutput": false,   // hide stdout from verbose mode
  "systemMessage": "warning" // warning shown to user
}
```

### Hook security settings

| Key | Scope | Description |
|---|---|---|
| `disableAllHooks` | any | Disables all hooks. Managed-level only can disable managed hooks. |
| `allowManagedHooksOnly` | managed only | Blocks user/project/plugin hooks. Only managed hooks run. |
| `allowedHttpHookUrls` | any, merges | Restricts HTTP hook target URLs. Supports `*` wildcard. Non-matching URLs are blocked. Undefined = no restriction, empty array = block all HTTP hooks. |
| `httpHookAllowedEnvVars` | any, merges | Restricts env var names for HTTP header interpolation. Effective set = **intersection** with handler's own `allowedEnvVars`. |
| 🆕 `autoMemoryDirectory` | policy, local, user (NOT project settings — prevents shared repos redirecting memory writes) | Custom directory for auto-memory storage. Supports `~/` expansion. Useful for synced drives or shared team memory. |

### Environment variables available to hook commands

| Variable | Available in |
|---|---|
| `CLAUDE_PROJECT_DIR` | All hooks |
| `CLAUDE_SESSION_ID` | All hooks (v2.1.9+) |
| `CLAUDE_CODE_REMOTE` | All hooks (`"true"` in remote web environments) |
| `CLAUDE_ENV_FILE` | `SessionStart`, `CwdChanged`, `FileChanged` — write `export VAR=value` lines to persist vars |
| `CLAUDE_PLUGIN_ROOT` | Plugin hooks only |
| `CLAUDE_PLUGIN_DATA` | Plugin hooks only — persistent state dir that survives plugin updates |
| 🆕 `CLAUDE_CODE_MCP_SERVER_NAME` | MCP-related hook contexts |
| 🆕 `CLAUDE_CODE_MCP_SERVER_URL` | MCP-related hook contexts |

---

## 6. Output style — .claude/output-styles/*.md

**Locations:** user (`~/.claude/output-styles/`) > project (`.claude/output-styles/`)

```yaml
---
name: My Custom Style          # REQUIRED. Shown in style picker
description: Brief description # REQUIRED. Shown in style picker
keep-coding-instructions: false # optional. 🆕 default false. true = keep coding-related system prompt parts.
---
# Custom system prompt content
# By default, this REPLACES Claude Code's engineering system prompt. Set keep-coding-instructions: true to retain it.
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
| `name` field | optional (defaults to dir name) | ❌ (filename) | ✅ required | ❌ invalid | — |
| `description` field | recommended (falls back to first paragraph) | ✅ required | ✅ required | ❌ invalid | — |
| `model` field | ✅ | ✅ | ✅ | ❌ | ✅ (prompt/agent types) |
| 🆕 `effort` field | ✅ | ✅ | ✅ | ❌ | — |
| `allowed-tools` / `tools` | ✅ | ✅ | ✅ | ❌ | — |
| `hooks` in frontmatter | ✅ | ❌ | ✅ | ❌ | N/A |
| `paths` (auto-activation scope) | 🆕 ✅ | ❌ | ❌ | ✅ only field | — |
| `context: fork` ⭐ | ✅ | ❌ **primary reason to use skill over command** | — | ❌ | — |
| `permissionMode` | ❌ | ❌ | ✅ | ❌ | — |
| `memory` | ❌ | ❌ | ✅ | ❌ | — |
| `shell` | 🆕 ✅ | ❌ | ❌ | ❌ | ✅ (command handlers) |
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
- 🆕 `paths` on skills works like `paths` on rules — scopes auto-activation to matching files
- 🆕 Skill descriptions are truncated at 250 characters in the skill listing. Front-load the key use case
- 🆕 Description budget scales at 1% of context window (fallback 8K chars). Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET`

### Subagents
- Omitting `tools` gives the subagent **all tools including MCP** — always be explicit
- `permissionMode: bypassPermissions` on the parent silently cascades — you cannot override it per-subagent
- 🆕 If parent uses **auto mode**, subagent inherits it — `permissionMode` in frontmatter is ignored; classifier evaluates subagent tool calls
- 🆕 `initialPrompt` only takes effect when running as `--agent` or via `agent` setting — ignored when spawned as a subagent
- 🆕 `Agent(worker, researcher)` in `tools` field restricts which subagent types can be spawned (only for `--agent` main thread agents)
- 🆕 Plugin subagents do NOT support `hooks`, `mcpServers`, or `permissionMode` — those fields are silently ignored
- Two separate memory systems exist — don't confuse them:

| System | Purpose | Paths |
|---|---|---|
| **Agent memory** (subagent `memory:` field) | Per-subagent, persists across conversations | `user` → `~/.claude/agent-memory/<name>/`<br>`project` → `.claude/agent-memory/<name>/`<br>`local` → `.claude/agent-memory-local/<name>/` |
| **Auto memory** (session-level) | Per-project, written by Claude during sessions | `~/.claude/projects/<project>/memory/` — relocatable via `autoMemoryDirectory` setting |

### Hooks — response formats
- **Command hooks**: exit 0 + JSON on stdout OR exit 2 + stderr. Exit 2 ignores stdout entirely. JSON only parsed on exit 0.
- **Prompt/agent hooks**: return `{"ok": true}` or `{"ok": false, "reason": "..."}` — different format from command/http hooks
- **PreToolUse** (command/http): `hookSpecificOutput.permissionDecision` (`allow`|`deny`|`ask`|`defer`) + `permissionDecisionReason`. Top-level `decision`/`reason` deprecated.
- **PostToolUse / Stop / SubagentStop** (command/http): top-level `decision: "block"` + `reason`. `hookSpecificOutput` for `additionalContext` and `updatedMCPToolOutput` only.
- **PermissionRequest** (command/http): `hookSpecificOutput.decision.behavior` (`allow`|`deny`) + `updatedPermissions`
- **PermissionDenied**: `hookSpecificOutput.retry: true` only
- **Multiple PreToolUse decisions**: precedence is `deny` > `defer` > `ask` > `allow`
- **Universal fields** (all events): `continue: false` stops Claude entirely, `stopReason`, `suppressOutput`, `systemMessage`

### Hooks — handler type restrictions
- **`SessionStart`**: only `type: "command"` supported — no http, prompt, or agent
- **`StopFailure`**: output and exit code ignored entirely
- **`InstructionsLoaded`**: no decision control — observability only, runs asynchronously
- **`Notification`, `SubagentStart`, `CwdChanged`, `FileChanged`, `PreCompact`, `PostCompact`, `SessionEnd`, `WorktreeRemove`**: cannot block
- `async: true` is **command-type only** — not supported on http, prompt, or agent handlers
- ⚠️ `type: "agent"` errors on `PostToolUse` events (v2.1.89) — use `type: "prompt"` instead. `type: "agent"` works on `Stop` and `PreToolUse`. Re-test after upgrades.

### Hooks — execution behavior
- All matching hooks run **in parallel** — no sequential guarantee
- Deduplication: command hooks by command string, HTTP hooks by URL
- Hook stdout output capped at **10,000 characters** — exceeding saves to file with path + preview
- `Stop` hook: always check `stop_hook_active` field — if true, approve unconditionally to avoid infinite loop
- `Stop` and `SubagentStop` hooks receive `last_assistant_message` field
- `"defer"` only works when Claude makes a **single tool call** in the turn — ignored with warning if multiple
- `CLAUDE_ENV_FILE` available in `SessionStart`, `CwdChanged`, and `FileChanged` only
- `PermissionDenied` only fires in **auto mode** — not on manual deny, PreToolUse block, or deny rule match

### Hooks — field gotchas
- `if` field: tool events only (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`). On other events, hook with `if` set **never runs**.
- `if` field: one pattern per handler, no OR syntax. Use separate handlers for multiple patterns.
- `if` condition filtering handles compound commands (`ls && git push`) and env-prefixed commands (`FOO=bar git push`)
- `once` field: **skills only**, not agents
- `matcher`: regex against event-specific field. Events without matcher support (`UserPromptSubmit`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `CwdChanged`) — always fire.
- `$CLAUDE_PROJECT_DIR` expands in `type: "command"` commands but NOT in `type: "prompt"`/`type: "agent"` prompts (those are LLM text, not shell). Use relative paths in prompt/agent hooks.
- PreToolUse/PostToolUse hooks receive `file_path` as absolute path for Write/Edit/Read tools
- `StopFailure` fires on API errors — output and exit code ignored. Non-blocking.
- `TaskCreated` exit 2 rolls back task creation
- `CwdChanged` fires on directory change — useful for env var reload via `CLAUDE_ENV_FILE`
- `FileChanged` matcher is `filename` (basename, e.g. `.env`, `package.json`)

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

### Bash permission rules — redirect matching
- `Bash(python:*)` now also matches `python script.py > output.txt` — output redirections are covered by the rule
- Previously, redirect variants could bypass pattern-based allow/deny rules — this is now fixed
- Update any existing deny rules that were written with workarounds for this gap

### Settings — autoMemoryDirectory
- `"autoMemoryDirectory": "/path/to/dir"` — configure a custom directory for auto-memory storage
- Useful when you want memory files stored outside the default location (e.g., a synced drive, a shared team directory)

### /context command — actionable optimization suggestions
- `/context` now identifies context-heavy tools, memory bloat, and capacity warnings
- Includes specific optimization tips (e.g., "use context: fork for this skill", "this rule is loading too early")
- Use it proactively when sessions feel slow or context is filling up

### Read tool — PDF pages parameter
- `pages: "1-5"` reads specific page ranges from PDFs instead of the full document
- Large PDFs (>10 pages) now return a lightweight reference when @-mentioned instead of being inlined
- Update `allowed-tools` guidance: PDF-heavy skills benefit from scoped page reads

### Skills — hot-reload
- Skills created or modified in `~/.claude/skills/` or `.claude/skills/` are now immediately available without restarting the session
- No restart needed after installing or editing a skill during development

### Agent tool — model parameter restored
- `model` parameter on the Agent tool works again for per-invocation model overrides
- Subagent `model` field in frontmatter sets the default; Agent tool `model` overrides it per-call

### Hook events — InstructionsLoaded (observability)
- Fires when CLAUDE.md or `.claude/rules/*.md` files are loaded
- Input fields: `file_path`, `memory_type` (User/Project/Local/Managed), `load_reason` (session_start/nested_traversal/path_glob_match/include), `globs`, `trigger_file_path`, `parent_file_path`
- Non-blocking, no output schema — useful for logging/auditing which context files load and why

### Hook events — PostCompact
- Fires after context compaction completes (manual or auto)
- Input fields: `trigger` (manual/auto), `compact_summary` (the generated conversation summary)
- Non-blocking — useful for logging compaction events or persisting summaries

### Hook events — Elicitation & ElicitationResult
- `Elicitation`: fires when an MCP server requests user input (form or auth URL)
- `ElicitationResult`: fires after user responds to the elicitation
- Input fields: `mcp_server_name`, `message`, `mode` (form/url), `url`, `elicitation_id`, `requested_schema`, `action` (accept/decline/cancel), `content`
- Both can block: exit 2 or `hookSpecificOutput.action: "decline"` to reject
- Use case: auto-approve known MCP servers, log auth flows, enforce MCP interaction policies

### Hook events — Setup deprecated
- The `Setup` event no longer appears in official docs as of March 2026
- Likely replaced by `InstructionsLoaded` for observability and `SessionStart` for initialization
- Existing `Setup` hooks should be migrated

### PostToolUse/PostToolUseFailure — additional output fields
- `updatedMCPToolOutput`: in PostToolUse `hookSpecificOutput`, allows rewriting MCP tool output before Claude sees it
- `is_interrupt`: boolean field in PostToolUseFailure input, indicates whether failure was due to user interrupt

### Skills — `--add-dir` skill loading
- Skills in `.claude/skills/` within directories added via `--add-dir` are auto-loaded with live change detection
- CLAUDE.md files from `--add-dir` are NOT loaded by default — set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to enable

### Environment variables — additional
- `SLASH_COMMAND_TOOL_CHAR_BUDGET`: override skill description budget (default: 1% of context window, fallback 8K chars)
- `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`: timeout for SessionEnd hooks (default 1500ms)
- `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`: enable loading CLAUDE.md from `--add-dir` directories

### 🆕 Managed settings — drop-in directory (v2.1.83)
- `managed-settings.d/` directory for policy fragments — allows splitting managed policy across multiple files
- Located alongside the managed settings file

### 🆕 Hook `if` field — conditional filtering (v2.1.85)
- `"if": "Bash(git *)"` uses permission rule syntax for granular filtering
- More precise than `matcher` alone — e.g., match only `rm` commands within all Bash, or only `.ts` files within all Edit calls
- Available on all four handler types (command, http, prompt, agent)

### 🆕 Hook `"defer"` decision — headless pause/resume (v2.1.89)
- `PreToolUse` hooks can return `{"permissionDecision": "defer"}` to pause headless sessions
- Session pauses at the tool call and can be resumed with `-p --resume`
- Useful for human-in-the-loop approval in CI/CD pipelines

### 🆕 `PermissionDenied` hook event (v2.1.89)
- Fires after auto mode classifier denies a tool call
- Return `{retry: true}` from the hook to tell the model it can retry
- Non-blocking — informational + retry signal

### 🆕 `CwdChanged` and `FileChanged` hook events (v2.1.83)
- `CwdChanged`: fires when working directory changes. No matcher. Non-blocking. `CLAUDE_ENV_FILE` available.
- `FileChanged`: fires when watched files change on disk. Matcher: `filename` (basename). Non-blocking. `CLAUDE_ENV_FILE` available.
- Both support writing env vars via `CLAUDE_ENV_FILE` — useful for reactive environment configuration

### 🆕 `TaskCreated` hook event (v2.1.83)
- Fires when task created via `TaskCreate` tool
- Blocking: exit 2 rolls back task creation
- Use for validation or logging of task creation

### 🆕 Subagent `initialPrompt` field (v2.1.83)
- Auto-submitted as the first user turn when agent runs as main session agent (`--agent` or `agent` setting)
- Commands and skills in the prompt are processed (e.g., `/setup`)
- Prepended to any user-provided prompt
- Ignored when spawned as a subagent

### 🆕 `sandbox.failIfUnavailable` setting (v2.1.83)
- Set to `true` to exit Claude Code if sandbox isolation is unavailable
- Useful for security-critical environments

### 🆕 `TaskOutput` tool deprecated (v2.1.83)
- Use `Read` on the output file path instead
- `TaskOutput` still works but is no longer recommended

### 🆕 Keybinding change (v2.1.83)
- `Ctrl+F` (stop all agents) moved to `Ctrl+X Ctrl+K`
- `Ctrl+X Ctrl+E` added as alias for external editor (`Ctrl+G` still works)
