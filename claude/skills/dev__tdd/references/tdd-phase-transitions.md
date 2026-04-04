# TDD Phase Transition Rules

This reference helps dev__tdd by defining exact phase boundaries, permissions, and transition criteria for the RED/GREEN/REFACTOR cycle.

## Phase Definitions

### RED Phase
- **Goal**: Write ONE failing test
- **Can write**: Test files, fakes, fixtures
- **Cannot write**: Production code
- **Exit criteria**: New test FAILS, all previous tests still pass
- **Hook enforcement**: `tdd-guard.sh` denies Edit/Write to non-test files

### GREEN Phase
- **Goal**: Write minimum production code to make the failing test pass
- **Can write**: Production code only
- **Cannot write**: Test files (locked)
- **Exit criteria**: ALL tests pass (green)
- **Hook enforcement**: `tdd-guard.sh` denies Edit/Write to test files
- **If test seems wrong**: STOP, escalate to user. Do not silently modify tests.

### REFACTOR Phase
- **Goal**: Improve code structure without changing behavior
- **Can write**: Production code only
- **Cannot write**: Test files (locked)
- **Exit criteria**: ALL tests still pass after refactoring
- **Skip condition**: If nothing to improve, move directly to next RED

## Phase Transition Protocol

```
RED → GREEN:
  Trigger: New test fails (verified by running test suite)
  Action: Write "green" to .claude/tdd-phase
  Approval: User says "yes" to proceed

GREEN → REFACTOR:
  Trigger: All tests pass
  Action: Write "refactor" to .claude/tdd-phase
  Approval: User says "yes" to proceed

REFACTOR → RED (next test):
  Trigger: Refactoring complete OR skipped, all tests still green
  Action: Write "red" to .claude/tdd-phase
  Approval: User says "yes" to proceed
```

## Mid-Phase Transitions

### GREEN discovers missing test case
When implementing production code reveals an untested edge case:
1. Pause GREEN phase
2. Write "red" to .claude/tdd-phase
3. Add the missing test (must FAIL)
4. Write "green" to .claude/tdd-phase
5. Continue implementing

### GREEN believes test is wrong
When production code cannot satisfy a test that appears incorrect:
1. STOP implementation
2. Explain to user why test seems wrong
3. User decides: fix test (switch to RED) or continue (test is correct)
4. Never silently work around a bad test

## Per-Test Loop (Orchestrated Mode)

Each acceptance criterion drives one or more tests. For each test:

```
1. RED:    Write one failing test (simplest TPP transformation next)
2. RUN:    Verify new test fails, previous tests pass
3. GREEN:  Write minimum code to pass
4. RUN:    Verify all tests green
5. REFACTOR: Clean up if needed
6. RUN:    Verify all tests still green
7. REPEAT: Next test in TPP order
```

## File Locking Patterns

The `tdd-guard.sh` hook identifies test files by these patterns:
- `*.test.ts`, `*.spec.ts` (and .tsx/.js/.jsx variants)
- Files inside `__tests__/` directories
- Files inside `test/` directories
- `*.fake.*`, `in-memory-*`, `*.failing-stub*`
- `*fixture*`, `*.fixture.*`

Everything else is considered production code.

## Completeness Check

After all tests pass for a story:
- All acceptance criteria from prd.json are covered
- TPP reviewer approves test ordering and transformation choices
- LCOM metrics within thresholds
- No untested edge cases flagged during GREEN
