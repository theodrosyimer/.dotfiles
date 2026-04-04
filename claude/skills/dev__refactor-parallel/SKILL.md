---
name: refactor-parallel
description: "Dependency-aware parallel refactor across monorepo modules. Spawns workers per module respecting dependency tiers."
disable-model-invocation: true
context: fork
argument-hint: "<describe the change to apply across modules>"
model: opus
effort: high
---

## Parallel Module Refactor

Apply this change across the monorepo: **$ARGUMENTS**

## Phase 1 — Discover

1. Find all modules in `packages/modules/src/*/`
2. For each module, read `package.json` and `tsconfig.json`
3. Build a dependency graph from:
   - `tsconfig.json` path mappings (which modules reference which)
   - Import statements in `contracts/` directories (Gateway/ACL dependencies)
   - `package.json` dependencies between workspace packages
4. Group modules into **dependency tiers**:
   - Tier 0: `src/core/` (no module dependencies)
   - Tier 1: modules that depend only on core
   - Tier 2: modules that depend on Tier 1 modules
   - ... and so on
5. Present the dependency graph and tier assignments. List which modules will be affected by the
   requested change and which can be skipped.

## Phase 2 — Baseline

Run each affected module's test and type-check scripts (read from `package.json`):
- If any module fails baseline, report it and ask whether to proceed without it or abort

## Phase 3 — Execute by Tier

For each tier, starting from Tier 0 (upstream) to the highest tier (downstream):

1. Spawn one `module-worker` subagent per module in this tier — **all in parallel**
2. Each worker receives:
   - Module path
   - Change description: `$ARGUMENTS`
   - Dependency context: what upstream modules already changed (if any)
3. Wait for ALL workers in this tier to complete
4. Collect results:
   - **All passed**: proceed to next tier
   - **Some failed**: report which modules failed and why. Ask: continue to next tier or stop?
   - **Port interface change needed**: a worker reported it needs to modify a cross-module
     contract. STOP — this requires manual coordination. Present the issue.

## Phase 4 — Verify

1. Run full monorepo test suite from root
2. Run full type-check from root
3. Report summary:
   - Modules changed (with file counts)
   - Modules skipped (with reasons)
   - Modules that failed (with error summaries)
   - Test status: pass/fail
   - Type-check status: pass/fail

## Rules

- NEVER skip the baseline check
- NEVER proceed to next tier until current tier is fully resolved
- NEVER let workers edit outside their module boundary
- If the change touches `src/core/` or `src/shared/`, those go in Tier 0 — before any module
- Workers use module-specific `package.json` scripts, never hardcoded commands
