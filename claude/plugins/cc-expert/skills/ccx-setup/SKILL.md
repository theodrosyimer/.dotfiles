---
name: ccx-setup
description: >
  Full Claude Code project setup wizard. Sequences context-optimizer → cc-architect →
  cc-primitives to build a complete, validated automation setup from scratch or audit and
  upgrade an existing one. Use when starting a new project's Claude Code configuration,
  doing a full setup review, or onboarding a new repo. Triggers on "set up Claude Code",
  "scaffold my Claude setup", "full setup wizard", "audit my entire Claude config".
disable-model-invocation: true
context: fork
allowed-tools: Read, Write, Bash, Grep, Glob
---

# ccx-setup — Full Claude Code Setup Wizard

You orchestrate three specialist subagents sequentially. Each phase depends on the previous.
Do not run phases in parallel.

Before starting, tell the user:

> "Running full Claude Code setup — 3 phases: Foundation → Design → Validate.
> This runs in an isolated context so your session stays clean. I'll report when done."

---

## Phase 1 — Foundation

Delegate to the `ccx-setup-context` subagent.

This subagent runs the `ccx-context-optimizer` skill, which audits or creates the always-on
foundation of your Claude Code setup:

- **CLAUDE.md** — project overview, build commands, architecture summary, conventions.
  Kept under 200 lines. Workflow content does NOT go here (that's Phase 2).
- **`.claude/rules/`** — domain-specific rule files (e.g., `testing.md`, `api-design.md`,
  `security.md`) with `paths:` frontmatter so they only load when relevant files are accessed.

If CLAUDE.md and rules already exist, context-optimizer audits them for bloat, redundancy,
and anti-patterns — and restructures rather than overwrites.

Pass it:

- The project root path (ask the user if not already known)
- Any conventions or constraints the user mentioned
- Whether this is a fresh setup or an audit of an existing one

Wait for it to complete. Collect its summary — what was created or changed in CLAUDE.md
and .claude/rules/.

---

## Phase 2 — Design & Scaffold

Delegate to the `ccx-setup-architect` subagent.

Pass it:

- The Phase 1 summary (what conventions now exist)
- The user's automation goals (what they want to build)
- The project root path

Wait for it to complete. Collect its summary — what files were scaffolded and where.

---

## Phase 3 — Validate

Delegate to the `ccx-setup-validator` subagent.

Pass it:

- The project root path
- The list of files created in Phase 2

Wait for it to complete. Collect its findings.

---

## Final Report

Synthesize all three summaries into a single structured report:

```
## ✅ Phase 1 — Foundation
<what ccx-context-optimizer created or changed>

## ✅ Phase 2 — Design & Scaffold
<what ccx-architect scaffolded, with file paths>

## Phase 3 — Validation
<🔴 errors that must be fixed>
<🟡 upgrades available>
<🔵 suggestions>

## TODO markers
<all # TODO: items across all generated files, grouped by file>

## Next upgrade
<what Stage N+1 looks like for this project>
```

If Phase 3 found 🔴 errors, ask the user if they want you to fix them before finishing.
