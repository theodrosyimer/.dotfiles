# Restructure Guide — Optimal Context File Architecture

## Target Architecture

```
Project Root
├── CLAUDE.md                        ← Protocol file: routing + landmines (always loaded)
├── .claude/
│   ├── rules/                       ← Scoped constraints (auto-loaded per matching paths)
│   │   ├── schema-first.md             paths: modules, api
│   │   ├── design-tokens.md            paths: design-system, ui, front tsx
│   │   └── caching.md                  paths: infrastructure, api, hooks
│   ├── skills/                      ← On-demand playbooks (loaded when agent decides)
│   │   ├── development/
│   │   ├── architecture/
│   │   └── infrastructure/
│   └── commands/                    ← Slash commands (user-triggered)
├── apps/
│   └── front/
│       └── CLAUDE.md                ← Directory-scoped (loaded when agent reads files here)
├── packages/
│   └── modules/
│       └── CLAUDE.md                ← Directory-scoped (loaded when agent reads files here)
```

## Layer Responsibilities

### Layer 1: Root CLAUDE.md — Protocol File
**Always loaded. Every session. Every task.**

This means every line competes with the actual prompt. Be ruthless.

Contains ONLY:
- Communication style (3-5 bullets)
- Project-wide landmines (5-10 bullets max)
- Tool routing (MCP, doc fetching — 3-4 bullets)
- Key skill pointers (2-3 lines)
- Context maintenance instruction (1 paragraph)

Does NOT contain:
- Codebase overview
- Directory structure
- Available commands
- Workflow descriptions
- Anything domain-specific (that belongs in scoped rules)

### Layer 1b: .claude/rules/ — Scoped Constraints
**Auto-loaded when working on matching paths. Same priority as CLAUDE.md.**

Each rule file:
- Has `paths:` frontmatter limiting when it loads
- Contains only constraints and prohibitions ("never", "always", "must")
- Short — under 60 lines per file
- No implementation details (those go in skills)

When to create a new rule file:
- You have 3+ constraints that apply to the same set of file paths
- The constraints are non-discoverable landmines
- They're "always in effect" when touching those files

### Layer 2: .claude/skills/ — On-Demand Playbooks
**Loaded only when the agent decides it needs them.**

Skills contain:
- Implementation patterns and templates
- Step-by-step workflows
- Code examples and scaffolding
- Reference documentation
- Architecture decision rationale

Skills are already well-separated if you follow the rule: **if it tells you HOW to do something, it's a skill.**

### Layer 2b: Nested CLAUDE.md — Directory-Scoped Context
**Loaded on-demand when agent reads files in that directory.**

Use for:
- App-specific conventions that differ from project-wide defaults
- Module-specific gotchas that don't warrant a rule
- Directory-specific tooling (e.g., "this directory uses a custom build step")

Keep these extremely short (10-20 lines). They're for exceptions, not comprehensive guides.

## Restructure Workflow

### Step 1: Inventory
List all context-contributing files:
```bash
# Root context
cat CLAUDE.md

# Rules (auto-loaded, high priority)
ls .claude/rules/*.md

# Nested context (on-demand)
find . -name "CLAUDE.md" -not -path "./node_modules/*" -not -path "./.claude/*"

# Skills (on-demand, already correct loading behavior)
find .claude/skills -name "SKILL.md"
```

### Step 2: Audit
Run Mode 1 (Audit) on every file found in Step 1. Classify each line.

### Step 3: Redistribute

For each classified line:

| Classification | Action |
|---|---|
| DELETE | Remove the line |
| SCOPE | Add/update `paths:` frontmatter in the rule file |
| MOVE TO SKILL | Copy to appropriate skill's SKILL.md or references/, delete from rule |
| PROMOTE TO CLAUDE.md | Add to root CLAUDE.md protocol section, delete from original location |
| KEEP | No action needed |

### Step 4: Generate New CLAUDE.md
Use the template in `references/claude-md-template.md` to create the optimized protocol file.

### Step 5: Validate
After restructuring, verify:
- [ ] Root CLAUDE.md is under 40 lines of actual content
- [ ] Every rule file has `paths:` frontmatter (unless truly universal)
- [ ] No rule file exceeds 60 lines
- [ ] No discoverable information remains in any context file
- [ ] No implementation details remain in rules (moved to skills)
- [ ] No duplicated content across files
- [ ] Context maintenance instruction is present in CLAUDE.md

### Step 6: Present Changes
Show the user a summary:
- Files deleted
- Files modified (with diffs)
- New files created
- Total lines before vs after
- Estimated context reduction percentage
