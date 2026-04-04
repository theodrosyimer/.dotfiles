---
name: convention-enforcer
description: "Audit and fix convention violations across monorepo. Learns from compliant code, fixes in dependency order."
disable-model-invocation: true
context: fork
argument-hint: "<convention rule to enforce>"
model: opus
effort: high
---

## Convention Enforcer

Enforce this convention across the monorepo: **$ARGUMENTS**

## Phase 0 — Convention Discovery

1. Check if `.claude/rules/` contains convention files (e.g., `naming-conventions.md`):
   - **Found**: Read matching rule files — these are the source of truth. Use them as the
     convention definition for auditing. Save the rule file location to agent memory.
   - **Not found**: Check agent memory for previously saved convention locations.
2. If no conventions found anywhere, use AskUserQuestion with these options:
   - "Describe conventions inline" — user types the convention rules in the response
   - "Point to a file" — user provides a path to a convention definition file
   - "Help me define conventions" — walk the user through defining conventions using the
     structured format from `references/convention-template.md` (CONVENTION, COMPLIANCE,
     VIOLATIONS, SCOPE, EXCEPTIONS), then save the result as a new rule file in `.claude/rules/`
3. Merge the discovered convention rules with `$ARGUMENTS` — the argument may refine or scope
   the conventions (e.g., "enforce naming conventions in booking module only").

## Phase 1 — Audit

1. Find all modules in `packages/modules/src/*/` plus `src/core/` and `src/shared/`
2. Spawn one `module-auditor` subagent per module — **all in parallel** (read-only, safe)
3. Each auditor receives:
   - Module path
   - Convention rule: `$ARGUMENTS`
4. Collect structured violation reports from all auditors

## Phase 2 — Plan

1. Aggregate violations across modules:
   - Total violation count per module
   - Violation categories (group similar violations)
   - Severity breakdown (error vs warning)
2. Extract **compliant code examples** from auditor reports — these are real examples from the
   codebase that already follow the convention correctly
3. Build dependency tiers (same logic as `refactor-parallel`):
   - Tier 0: core/shared
   - Tier N: modules by dependency depth
4. Present the plan to the user:
   - Violation summary table (module | count | severity)
   - Sample violations (3-5 representative examples)
   - Compliant examples that will guide fixes
   - Estimated scope per tier
5. **Wait for user approval before proceeding to Phase 3**

## Phase 3 — Fix

For each tier (upstream → downstream):

1. Spawn one `module-worker` subagent per module in this tier — **all in parallel**
2. Each worker receives:
   - Module path
   - Convention rule: `$ARGUMENTS`
   - Violation list for this module (from Phase 1 auditor report)
   - Compliant code examples (from Phase 2) — worker uses these as reference patterns
3. Worker applies fixes guided by real examples, not abstract rules
4. Worker tests after each fix using module's `package.json` scripts
5. Wait for all workers in tier to complete before moving to next tier

## Phase 4 — Verify

1. Run full monorepo test suite + type-check from root
2. **Re-audit**: Spawn auditors again on all modules that had violations
3. Compare: original violation count vs remaining violations
4. Report:
   - Violations fixed (count, by module)
   - Violations remaining (count, by module, with reasons — e.g., worker couldn't fix without
     breaking tests, or port interface change needed)
   - Test status: pass/fail
   - Type-check status: pass/fail
   - Compliant examples discovered (for future reference)

## Rules

- NEVER skip Phase 2 user approval — the user must see the plan before fixes begin
- NEVER let workers modify files outside their module boundary
- Auditors are strictly read-only — they discover, they don't fix
- Workers use module-specific `package.json` scripts, never hardcoded commands
- If a fix requires modifying a cross-module contract (port/gateway), flag it as unresolvable
  by the worker — it needs manual coordination
