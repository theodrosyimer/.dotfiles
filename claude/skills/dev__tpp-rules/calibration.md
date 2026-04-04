# TPP Evaluator Calibration

Self-correcting catalog of TPP judgment **examples** (not the rules themselves).
For the full TPP priority list and rules, read `SKILL.md` in this same directory.

Read by the TDD Stop hook's TPP reviewer agent before evaluating. Updated by the
TDD orchestrator after each story. Over time, aligns the evaluator with this
project's TPP interpretation.

---

## Example Correct Transformation Sequences (APPROVE)

| Test | Transformation | Verdict | Reasoning |
|---|---|---|---|
| "should return null for unknown ID" | `{}→nil` | APPROVE | Simplest: return nothing |
| "should return a fixed booking" | `nil→constant` | APPROVE | One step down: hardcode the return |
| "should return booking by ID" | `constant→scalar` | APPROVE | One step: constant becomes parameterized |
| "should reject if already canceled" | `unconditional→if` | APPROVE | One step: add conditional guard |
| "should handle multiple bookings" | `scalar→collection` | APPROVE | One step: variable becomes array/map |

## Example Violations (BLOCK)

| Test | Transformation Applied | Expected | Verdict | Reasoning |
|---|---|---|---|---|
| Test 1: constant, Test 2: loop | `constant→while` | `constant→scalar` then `scalar→collection` then `if→while` | BLOCK | Skipped 3 levels — needs intermediate tests |
| "should handle all bookings" after "should return one booking" | `scalar→collection` + `if→while` in one step | `scalar→collection` first, then `if→while` | BLOCK | Two transformations in one GREEN — write a test that only requires the collection, iterate to the loop |
| "should calculate total" with full reduce implementation | `expression→function` | `unconditional→if` first | BLOCK | Jumped to function extraction when a conditional would suffice for the first case |

## Edge Cases (project-specific interpretations)

<!-- Add entries here when the evaluator misjudges a transformation.
Format: [date] [test] [transformation] [correct verdict] [reasoning] -->

---

## Calibration Corrections Log

Record overrides here when the TPP reviewer misjudges. Format:
`[date] [test] [expected: APPROVE/BLOCK] [actual: APPROVE/BLOCK] [reasoning]`

<!-- Example:
[2026-04-02] "should evolve state for confirmed booking" APPROVE (was blocked — reviewer
thought scalar→collection was needed but this was still constant→scalar since only one
state variant was being handled)
-->
