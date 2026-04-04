---
name: implement-feature
description: "TDD GREEN phase: Implement the minimum code to make failing tests pass. Test files are locked — cannot be edited. TPP reviewer validates transformation choices on completion."
disable-model-invocation: true
argument-hint: "<feature or test to make pass>"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "TDD_PHASE=green $CLAUDE_PROJECT_DIR/.claude/hooks/tdd-guard.sh"
          timeout: 5
  Stop:
    - hooks:
        - type: agent
          agent: tpp-reviewer
          prompt: "GREEN phase review: The changed file list has been injected into your context by tdd-changed-files.sh — read the listed production and test files. For each test→implementation step, identify which TPP transformation was applied. Flag any step where a simpler transformation would have sufficed or where multiple transformation levels were skipped. If violations are found, block and explain which simpler transformation should have been used."
        - type: prompt
          prompt: "Check if the GREEN phase is complete. Verify: (1) ALL tests pass — not just some, (2) no test was skipped or commented out, (3) test output confirms full GREEN state. If any test still fails or was bypassed, respond {\"decision\": \"block\", \"reason\": \"description of what remains\"}. If all tests pass, respond {\"decision\": \"approve\"}."
---
ultrathink

## TDD GREEN Phase: Make Tests Pass

Feature: $ARGUMENTS

## Rules — READ CAREFULLY
1. Test files are LOCKED. You CANNOT edit any test file. The hook will block you.
2. If a test is wrong, STOP and tell me. Do NOT work around a bad test.
3. Write the MINIMUM code to make tests pass — no more, no less.
4. Do NOT add behavior that isn't tested. If it's not in a test, it doesn't exist yet.
5. Run tests after each meaningful change to track progress.

## Transformation Priority Premise (TPP) — Implementation Strategy
For each failing test, apply the SIMPLEST transformation from this priority list:
1. `{}→nil` — no code → return nothing
2. `nil→constant` — return a fixed value
3. `constant→constant+` — richer constant
4. `constant→scalar` — constant becomes variable/argument
5. `statement→statements` — add unconditional statements
6. `unconditional→if` — introduce conditional
7. `scalar→collection` — variable becomes collection
8. `statement→tail-recursion` — add tail recursion
9. `if→while/loop` — conditional becomes iteration
10. `statement→recursion` — general recursion
11. `expression→function` — extract to function
12. `variable→assignment` — mutate a value

**Always pick the transformation highest on this list that makes the current test pass.**
If you find yourself reaching for a loop when an `if` would suffice, you're over-engineering.
The TPP reviewer agent will validate your choices when you finish.

## Process
1. Read the failing tests to understand what behavior is expected
2. Read existing code to understand the architecture and patterns in use
3. For the first failing test, identify the simplest TPP transformation needed
4. Apply ONLY that transformation — resist the urge to implement the "final" solution
5. Run tests: `pnpm vitest run <test-file> --reporter=verbose`
6. If the first test passes, move to the next failing test and repeat from step 3
7. Repeat until ALL tests pass (GREEN state)
8. Report: which files were created/modified, test results showing all green, and the transformation path taken (e.g., "Test 1: nil→constant, Test 2: constant→scalar, Test 3: unconditional→if")

## Implementation references (all in this skill's references/)
- **Where logic goes**: `references/decision-framework.md` — two-question test, three layers, visual decision tree
- **Code patterns**: `references/implementation-guidelines.md` — entities, domain services, handlers with examples
- **Module layout**: `references/module-structure.md` — canonical file placement, dependency rules
- **Anti-patterns**: `references/anti-patterns.md` — anemic domain, infra in domain, logic in handlers
- **Checklist**: `references/implementation-checklist.md` — full sequence, quality rules, common mistakes
- **Entity patterns**: `references/entity-patterns.md` — rich entities, value objects, state transitions
- **Domain services**: `references/domain-service-patterns.md` — multi-entity coordination, stateless services
- **Handler patterns**: `references/use-case-patterns.md` — workflows, transactions, event publishing
- **Cross-context**: `references/cross-context-patterns.md` — Gateway, ACL, event-driven patterns

## If tests won't pass
- Re-read the test carefully — are you implementing the right behavior?
- Check if you're using the correct port/adapter interfaces
- If a test seems genuinely wrong, STOP and explain why. I will fix it or run /write-tests again.
- If the simplest TPP transformation doesn't make the test pass, consider whether an intermediate test is missing — TELL ME so I can add it with /write-tests
