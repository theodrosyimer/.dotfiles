---
name: init-project
description: >
  Bootstrap project Claude Code context (CLAUDE.md, rules, commands) via interactive discovery
  + vault knowledge. Trigger: "init project", "new project", "set up claude context",
  "bootstrap", "add context to this project".
effort: high
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
argument-hint: "[project-name]"
---

# Init Project — Claude Context Scaffolding

Generate project-tailored Claude Code context by reading the user's knowledge base and running
interactive discovery. Output is a working CLAUDE.md + rules + commands — not generic boilerplate.

## Sources (read before generating)

1. **Global constraints**: `~/.dotfiles/claude/CLAUDE.md` — the user's master constraint doc
2. **Vault index**: `~/Dropbox/Notes/_index.md` → domain structure notes
3. **Vault conventions**: `~/Dropbox/Notes/_conventions.md`
4. **Available skills**: `ls ~/.dotfiles/claude/skills/`
5. **Existing project**: If code exists, scan package.json, tsconfig.json, directory structure
6. **Output templates**: `references/output-templates.md` — example outputs for different patterns

---

## Phase 1: Discovery

Two paths depending on whether the project already has code.

### Path A: Existing project

Scan first, confirm second:

1. Read `package.json` (dependencies, scripts, workspaces)
2. Read `tsconfig.json` (module resolution, paths)
3. `ls` top-level + `ls src/` to detect architecture pattern
4. Check for existing CLAUDE.md, .claude/ directory
5. Summarize findings to user: "I see NestJS + Drizzle + pnpm monorepo with 3 modules..."
6. Ask only about gaps: missing architecture decisions, unclear patterns

### Path B: Greenfield

Ask in **two grouped rounds** — not one question at a time.

**Round 1 — Shape:**
> What's the project? I need:
> 1. Name + one-line purpose
> 2. Architecture: modular monolith / monolith / microservices / library
> 3. Data: event-sourced / CRUD / hybrid
> 4. API: REST / GraphQL / tRPC / none

**Round 2 — Stack** (skip if user says "standard stack" or "same as usual"):
> Stack details:
> 1. Backend: NestJS / Fastify / none
> 2. Frontend: Expo / TanStack Start / both / none
> 3. Database: Postgres+Drizzle / SQLite / none
> 4. Initial modules/domains (if modular)
> 5. Observability: full (Pino+OTel+Sentry+Grafana) / basic / none yet

### Discovery rules

- **"Standard stack"** or **"same as usual"** = modular monolith + ES + NestJS + Expo + Drizzle +
  Turborepo + pnpm + full observability (user's default from global CLAUDE.md)
- Don't ask what you can discover from existing code
- Max 2 rounds of questions
- Offer defaults: "I'll assume pnpm + Turborepo unless you say otherwise"

---

## Phase 2: Knowledge Gathering

Read vault structure notes relevant to the user's choices. Don't read leaf notes unless you need
a specific pattern's details.

| Choice | Vault structure note |
|--------|---------------------|
| Modular monolith | `programming/architecture.md`, `programming/ddd.md` |
| Event sourcing | `programming/event-sourcing.md` |
| CRUD | `programming/databases.md` |
| NestJS / Node | `programming/node.md` |
| Web / API | `programming/web-development.md` |
| Expo / Mobile | `programming/mobile.md` |
| TDD / Testing | `programming/testing.md` |
| Error handling | `programming/error-handling.md` |
| DevOps / CI | `programming/devops.md` |
| Security | `programming/security.md` |
| Shell / Scripts | `programming/shell-scripting.md` |

Also read global CLAUDE.md sections to extract the relevant subset of constraints.

---

## Phase 3: Generation

Present the plan to the user before writing any files. List exactly which files will be created
and a brief summary of each. Get confirmation, then generate.

### File 1: `CLAUDE.md` (always)

Extract relevant sections from global CLAUDE.md. The project CLAUDE.md is a **tailored subset**,
not a copy. Add project-specific context the global doesn't have.

**Structure:**

```markdown
# {Project Name}

{One-line purpose}

## Communication
{From global — conciseness, challenge ideas, just answer}

## Project Structure
{Architecture-specific: module layout, folder conventions}
{Only if modular: module template with contracts/, domain/, infrastructure/, slices/}

## Landmines
{Stack-specific gotchas — only what applies to chosen stack}

## Architecture
{Selected patterns only: hexagonal, gateway/ACL, ES pure functions, etc.}
{Error architecture if NestJS backend}
{Domain modeling if ES/DDD}

## Testing
{TDD rules, fakes not mocks, fixture conventions — tailored to stack}

## Tech Stack
{Only selected technologies}
{Never Use — only relevant exclusions}

## Vault References
{Pointers to structure notes: "Architecture patterns: [[architecture]] in vault"}

## Skills
{List relevant skills with one-line descriptions}
```

**Critical rules:**
- Never copy the entire global CLAUDE.md — extract only relevant sections
- Add project-specific info: module names, domain terminology, integration notes
- `## Vault References` section points to `~/Dropbox/Notes/programming/` structure notes
- `## Skills` section lists skills from `~/.dotfiles/claude/skills/` relevant to the project

### File 2: `.claude/rules/` (pattern-specific)

Generate rules ONLY for patterns needing enforcement. Each rule: 5-20 lines, constraint + why.

| Pattern | Rule file | Content |
|---------|-----------|---------|
| Modular monolith | `module-boundaries.md` | No cross-module imports, gateway/ACL only |
| Event sourcing | `event-sourcing-purity.md` | decide/evolve pure, no side effects, state-level dispatch |
| Monorepo | `subpath-imports.md` | #src/* not @/*, no cross-package paths |
| NestJS | `error-architecture.md` | DomainError -> ApplicationException flow, never expose .cause |
| Any | `testing-conventions.md` | Fakes not mocks, vi.fn() only for React callbacks, fixtures as contracts |

Skip rules that duplicate global rules at `~/.dotfiles/claude/rules/`. Read those first.

### File 3: `.claude/commands/` (workflow shortcuts)

Generate commands as markdown files with `$ARGUMENTS` placeholder where needed.

**Always generate:**
- `review.md` — project-aware code review (checks architecture, patterns, conventions)

**If modular monolith:**
- `new-module.md` — scaffold module with contracts/, domain/, infrastructure/, slices/
- `new-slice.md` — scaffold vertical slice with handler, command, test, fixture

**If event sourced:**
- `new-aggregate.md` — scaffold aggregate with decide, evolve, project, react + initial test

**If has frontend:**
- `new-screen.md` — scaffold screen with route, component, hook

Command format:
```markdown
{Description of what this command does and when to use it}

{Detailed prompt with steps, constraints, and $ARGUMENTS usage}
```

---

## Phase 4: Validation

After generating all files:

1. **No overwrites** — if CLAUDE.md or .claude/ already exists, ask before overwriting
2. **No contradictions** — generated rules must not conflict with global CLAUDE.md
3. **No duplication** — don't duplicate global rules from `~/.dotfiles/claude/rules/`
4. **Vault refs valid** — verify referenced structure notes exist with `ls`
5. **Self-test** — re-read generated CLAUDE.md and ask: "Could an agent pick this up cold and
   work effectively?" If not, add what's missing.

---

## Conversation Flow

**Normal:** Full discovery (Phase 1) -> gather (Phase 2) -> present plan -> generate (Phase 3) -> validate (Phase 4)

**With $ARGUMENTS:** Use as project name, skip name question in discovery.

**"Same as usual" shortcut:** Skip Round 2 of discovery, use standard stack defaults.

**Existing project with CLAUDE.md:** Offer to audit/improve existing context rather than overwrite.
Read the existing files, identify gaps vs global CLAUDE.md, suggest additions.
