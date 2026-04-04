---
name: write-tests
description: "TDD RED phase: Write failing tests for a planned feature. Can only create/edit test files — production code is locked by a hook. TPP reviewer validates test ordering on completion."
disable-model-invocation: true
argument-hint: "<feature or test description>"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "TDD_PHASE=red $CLAUDE_PROJECT_DIR/.claude/hooks/tdd-guard.sh"
          timeout: 5
  Stop:
    - hooks:
        - type: agent
          agent: tpp-reviewer
          prompt: "RED phase review: The changed file list has been injected into your context by tdd-changed-files.sh — read the listed test files. Check if the test sequence follows TPP ordering — each test should require only one step down the transformation priority list. If a test would force the implementer to skip transformation levels, block and suggest intermediate tests."
        - type: prompt
          prompt: "Check if the RED phase is complete. Verify: (1) all planned test cases from the feature plan are written — not just some, (2) all tests fail when run (RED state), (3) any needed fakes/fixtures are created. If any planned tests are missing or any test passes unexpectedly, respond {\"decision\": \"block\", \"reason\": \"description of what's missing\"}. If everything is done, respond {\"decision\": \"approve\"}."
---
ultrathink

## TDD RED Phase: Write Failing Tests

Feature: $ARGUMENTS

## Rules — READ CAREFULLY
1. You can ONLY create and edit test files (*.test.ts, *.spec.ts, files in __tests__/)
2. You can also create fakes and test helpers (files in fakes/, fixtures/, helpers/, __mocks__/)
3. You CANNOT create or edit production code — the hook will block you
4. After writing tests, run them. They MUST FAIL. If they pass, something is wrong:
   - Either the feature already exists (verify and report)
   - Or your tests are not testing the right thing (fix the tests)
5. A test that passes before implementation is a useless test. Every test must be RED.

## Test writing guidelines
- Use Vitest (NOT Jest)
- Test at the use case boundary — call the use case, assert the result
- Use ultra-light fakes for infrastructure ports: XxxRepositoryFake (public fields, no Map), SequentialIdProvider, etc. (ADR-0016)
- Fakes are colocated with concrete siblings in `infrastructure/repositories/` and `infrastructure/gateways/` — NOT in a separate `fakes/` directory
- Use real domain services — no faking business logic
- One test = one behavior. Name tests as behaviors: "should reject expired tokens"
- Use the Arrange-Act-Assert pattern
- Use type aliases for data shapes, interfaces for behavior abstraction
- **No floating literal objects** — use `createXxxFixture()` factory functions for all test data (e.g., `createUserFixture({ email: 'test@example.com' })`). Factories validate via Zod schema and accept partial overrides.

## Transformation Priority Premise (TPP) — Test Ordering
Order your tests so each one requires only ONE step down the transformation priority list:
1. `{}→nil` → `nil→constant` → `constant→scalar` → `unconditional→if` → `if→while` → ...
2. If you're about to write a test that would force the implementer to jump from `constant` to `while`, STOP — write intermediate tests first (e.g., the single-element case before the collection case)
3. The TPP reviewer agent will validate your ordering when you finish — fix any violations before the user transitions to /implement-feature

## Process
1. Read the plan from the previous /plan-feature session (ask me if unclear)
2. Create test file(s) in the correct location
3. Write all test cases with clear descriptions, **ordered by TPP** (simplest transformation first)
4. Create any needed ultra-light fakes (XxxRepositoryFake, etc.) — these ARE allowed
5. Run the tests: `pnpm vitest run <test-file> --reporter=verbose`
6. Verify ALL tests fail (RED state)
7. Report: which tests were written, what each tests, confirmation they all fail, and the expected transformation path

If a test passes unexpectedly, investigate why and tell me before proceeding.
