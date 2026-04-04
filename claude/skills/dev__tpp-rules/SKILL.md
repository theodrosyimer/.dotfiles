---
name: tpp-rules
description: "Transformation Priority Premise (TPP) — Robert C. Martin's ordered list of code transformations for TDD. Simpler transformations should always be preferred."
user-invocable: false
---

## Transformation Priority Premise (TPP)

Robert C. Martin's principle: when making a failing test pass, always apply the SIMPLEST
transformation. Simpler transformations (top of list) should be preferred over complex ones (bottom).

### Priority List (Simplest → Most Complex)

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

### Core Rules

- **Pick the simplest transformation** that makes the current failing test pass
- **If you're jumping down the list**, the test is probably too big — write a simpler intermediate test
- **As tests get more specific, code gets more generic** — TPP guides this naturally
- **Avoid skipping levels** — jumping to a loop when an `if` suffices means over-engineering

### Applying TPP to Test Ordering (RED phase)

Each test in the sequence should require only ONE step down the priority list from the previous test.
If a test would force the implementer to skip multiple levels, insert intermediate tests.

Example violation: Test 1 expects a constant, Test 2 expects a loop — missing `constant→scalar`
and `unconditional→if` intermediate steps.

### Applying TPP to Implementation (GREEN phase)

For each failing test, identify the simplest transformation that makes it pass. If you find yourself
reaching for a loop when an `if` would suffice, you're applying a transformation that's too complex.
