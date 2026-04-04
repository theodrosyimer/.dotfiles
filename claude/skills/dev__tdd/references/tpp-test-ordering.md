# TPP Rules Applied to Test Ordering (RED Phase)

This reference helps dev__tdd by guiding which test to write next during the RED phase, using the Transformation Priority Premise to determine optimal test ordering.

## Core Principle

Each test in the sequence should require only ONE step down the TPP priority list from the previous test. If a test would force the implementer to skip multiple levels, insert intermediate tests.

## TPP Priority List (Simplest to Most Complex)

| # | Transformation | What it does | Example |
|---|---------------|-------------|---------|
| 1 | `{}->nil` | No code to return nothing | `return null` |
| 2 | `nil->constant` | Return a fixed value | `return 42` |
| 3 | `constant->constant+` | Richer constant | `return "hello"` |
| 4 | `constant->scalar` | Constant becomes variable/arg | `return input` |
| 5 | `statement->statements` | Add unconditional statements | Adding a second line |
| 6 | `unconditional->if` | Introduce conditional | `if (x) return a` |
| 7 | `scalar->collection` | Variable becomes collection | `int` to `int[]` |
| 8 | `statement->tail-recursion` | Add tail recursion | Recursive call at end |
| 9 | `if->while/loop` | Conditional becomes iteration | `if` to `while` |
| 10 | `statement->recursion` | General recursion | Recursive call mid-body |
| 11 | `expression->function` | Extract to function | Inline calc to `fn()` |
| 12 | `variable->assignment` | Mutate a value | `x = x + 1` |

## Test Ordering Rules

### Rule 1: One transformation step per test
Each new test should drive exactly one transformation in the production code. If you need two transformations, you need two tests.

### Rule 2: Walk the list, don't jump
Tests should progress through the priority list sequentially. Going from `nil->constant` (test 1) directly to `if->while` (test 2) skips too many levels.

### Rule 3: If stuck, the test is too big
When a test seems to require jumping multiple transformation levels, break it into smaller intermediate tests that walk through the missing levels.

## Practical Example: Test Ordering for Word Wrap

```
Test 1: wrap("", 5) -> ""
  Forces: {}->nil, then nil->constant ("")
  
Test 2: wrap("word", 10) -> "word"
  Forces: constant->scalar (return input)
  
Test 3: wrap("long text", 4) -> "long\ntext"
  Forces: unconditional->if (length check)
  
Test 4: wrap("very long string here", 4)
  Forces: if->while (handle multiple wraps)
```

Each test forces exactly one transformation step.

## Anti-Pattern Detection

The TPP reviewer catches these violations during RED phase:

**Skipped transformation**: Test jumps from constant directly to loop
- Fix: Add intermediate test requiring `unconditional->if` first

**Test too specific too early**: First test already requires conditional logic
- Fix: Start with degenerate case (empty input, null, default value)

**Multiple transformations per test**: Single test requires both conditional AND iteration
- Fix: Split into two tests, one per transformation

## Ordering Heuristic for Domain Tests

1. Start with degenerate/empty cases (`nil->constant`)
2. Add the simplest happy path (`constant->scalar`)
3. Add one business rule (`unconditional->if`)
4. Add collection/multiple items (`scalar->collection` or `if->while`)
5. Add error cases and edge cases last (they refine existing conditionals)

## Sources

- Robert C. Martin, "The Transformation Priority Premise" (2013)
- Robert C. Martin, "Fib. The T-P Premise" (follow-up with Fibonacci example)
