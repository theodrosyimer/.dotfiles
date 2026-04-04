# Transformation Priority Premise — Core Reference

This reference provides dev__tpp-rules with the complete TPP transformation list and application rules for both test ordering (RED) and implementation choices (GREEN).

## Priority List (Simplest to Most Complex)

| # | Transformation | Description | Example |
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

## Core Rules

1. **Pick the simplest transformation** that makes the current failing test pass
2. **If you're jumping down the list**, the test is probably too big -- write a simpler intermediate test
3. **As tests get more specific, code gets more generic** -- TPP guides this naturally
4. **Avoid skipping levels** -- jumping to a loop when an `if` suffices means over-engineering

## Applying TPP to Test Ordering (RED Phase)

Each test in the sequence should require only ONE step down the priority list. If a test forces the implementer to skip multiple levels, insert intermediate tests.

**Violation example**: Test 1 expects a constant, Test 2 expects a loop.
Missing: `constant->scalar` and `unconditional->if` intermediate steps.

## Applying TPP to Implementation (GREEN Phase)

For each failing test, identify the simplest transformation that makes it pass. If you find yourself reaching for a loop when an `if` would suffice, you're applying a transformation that's too complex.

**Over-engineering example**: Test says "return default pricing for a single space." Implementation builds a full pricing engine with conditionals and collections. The correct transformation is `nil->constant` (just return the price).

## Practical Example: Word Wrap

```
Test: wrap("", 5)         -> ""           // {}->nil, then nil->constant ("")
Test: wrap("word", 10)    -> "word"       // constant->scalar (return input)
Test: wrap("long text", 4)-> "long\ntext" // unconditional->if (length check)
Test: wrap("very long string here", 4)    // if->while (handle multiple wraps)
```

Each test forces exactly one transformation step.

## Key Insight

TPP prevents the "big leap" anti-pattern in TDD. Instead of guessing the final algorithm upfront, incremental transformations -- driven by progressively specific tests -- converge on the correct general solution.

## Relationship to TDD Cycle

```
RED:      Write failing test (small, specific)
GREEN:    Apply simplest TPP transformation
REFACTOR: Clean up without changing behavior
RED:      Next test forces next transformation
```

## Sources

- Robert C. Martin, "The Transformation Priority Premise" (2013)
- Robert C. Martin, "Fib. The T-P Premise" (Fibonacci example + language-specific ordering)
- Codurance, "Applying TPP to Roman Numerals Kata" (practical walkthrough)
