---
name: refactor
description:
  'TDD REFACTOR phase: Improve code quality without changing behavior. Test files remain locked —
  tests must stay green throughout.'
disable-model-invocation: true
argument-hint: "<what to refactor or 'all recent changes'>"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
hooks:
  PreToolUse:
    - matcher: 'Edit|Write'
      hooks:
        - type: command
          command: 'TDD_PHASE=refactor $CLAUDE_PROJECT_DIR/.claude/hooks/tdd-guard.sh'
          timeout: 5
---

## TDD REFACTOR Phase: Improve Without Breaking

Scope: $ARGUMENTS

## Rules — READ CAREFULLY

1. Test files are LOCKED. You CANNOT edit any test file.
2. All tests MUST remain GREEN after every change.
3. You are changing structure, NOT behavior. If a test breaks, you changed behavior — undo and try
   differently.
4. Run tests after EVERY refactoring step, not just at the end.

## Process

1. Run tests first to confirm they all pass (baseline)
2. Run architecture tests: `pnpm vitest run src/architecture/ --reporter=verbose`
3. Identify refactoring opportunities:
   - Extract method/class for long functions
   - Remove duplication
   - Improve naming
   - Simplify conditionals
   - Apply patterns from the codebase conventions
4. Make ONE refactoring change at a time
5. Run tests after each change: `pnpm vitest run <test-file> --reporter=verbose`
6. If tests break → undo the change, try a different approach
7. Run LCOM analysis on changed files (ArchUnitTS) — enforce thresholds:
   - Domain classes: LCOM < 0.5
   - Infrastructure adapters: LCOM < 0.7
   - Shared utilities: LCOM < 0.4
   - If any class exceeds its threshold, split it — high LCOM means low cohesion
8. Run architecture tests again to verify boundaries aren't violated
9. Report: what was refactored, why, tests still green, LCOM scores for changed classes

## Refactoring scope

- Production code only (test files are locked)
- Fakes ARE refactorable since they're test infrastructure, but their interface (the port) should
  not change
- If a port interface needs to change, STOP and tell me — that requires new tests first
