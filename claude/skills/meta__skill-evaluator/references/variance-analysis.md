# Variance Analysis Guide

How to interpret variance in skill evaluation results and what actions to take.

---

## Why Variance Matters

A skill that scores 9/10 on average but swings between 5 and 10 is worse than one that consistently hits 8. Without measuring variance, you're evaluating a single lucky (or unlucky) run.

**Variance tells you:** How reliable are the skill's instructions? Are they specific enough that Claude follows the same path each time?

---

## Interpreting Overall Variance

| stddev of overall_efficiency | Meaning | Action |
|------------------------------|---------|--------|
| < 0.05 | Highly reliable | None — skill is consistent |
| 0.05 - 0.10 | Reliable | Monitor — minor instruction tightening may help |
| 0.10 - 0.20 | Inconsistent | Investigate — find which dimensions have high variance |
| 0.20 - 0.30 | Unreliable | Rewrite ambiguous sections, add examples |
| > 0.30 | Broken | Major rewrite — instructions are fundamentally ambiguous |

---

## Per-Dimension Variance (More Actionable)

Overall variance hides where the problem is. Always check per-dimension stats:

```json
"rubric_dimensions": {
  "tdd_philosophy": {"mean": 4.2, "stddev": 1.1},   // ← HIGH variance
  "fixture_pattern": {"mean": 4.5, "stddev": 0.3},   // ← low variance
  "naming_conventions": {"mean": 4.8, "stddev": 0.2}  // ← low variance
}
```

This tells you: TDD philosophy guidance is ambiguous (high variance) while naming conventions are clear (low variance). Fix the TDD section of SKILL.md.

### What High Per-Dimension Variance Means

| Dimension with high variance | Likely cause | Fix |
|------------------------------|-------------|-----|
| `tdd_philosophy` | Abstract principle without concrete examples | Add specific do/don't examples |
| `fake_driven_correctness` | Boundary rule unclear for edge cases | List explicit cases: "fake this, don't fake that" |
| `fixture_pattern` | Factory pattern not demonstrated | Add template code in SKILL.md |
| `coverage_completeness` | No checklist of what to cover | Add explicit coverage checklist |
| `naming_conventions` | Conventions buried in text | Add a quick-reference table |
| `test_readability` | No structure template provided | Add Given/When/Then template |

---

## Per-Assertion Patterns

When analyzing benchmark results across multiple runs, look for these patterns:

### Always passes in both configurations
```
Assertion "File exists" — pass rate: 100% (with_skill), 100% (without_skill)
```
**Meaning:** Non-discriminating assertion. It doesn't prove the skill adds value.
**Action:** Keep as a basic sanity check (structural gate) but don't count it in the quality score.

### Always fails in both configurations
```
Assertion "TypeScript compiles" — pass rate: 0% (with_skill), 0% (without_skill)
```
**Meaning:** Either the assertion is broken, or the capability is beyond what the skill/model can do.
**Action:** Verify the assertion is correct. If it is, this is a skill gap to address.

### Passes with skill, fails without
```
Assertion "Uses fixture factories" — pass rate: 90% (with_skill), 10% (without_skill)
```
**Meaning:** The skill clearly adds value for this behavior. This is what you want.
**Action:** None — this proves the skill works.

### Fails with skill, passes without
```
Assertion "Concise test setup" — pass rate: 40% (with_skill), 70% (without_skill)
```
**Meaning:** The skill might be hurting this dimension. Its instructions may cause over-engineering or unnecessary complexity.
**Action:** Investigate — read transcripts from failing runs to understand what went wrong.

### High variance (flaky)
```
Assertion "Covers edge cases" — pass rate: 50% ± 40%
```
**Meaning:** Non-deterministic behavior. The skill sometimes guides Claude to cover edge cases and sometimes doesn't.
**Action:** Make the instruction more explicit. Add a checklist: "Always test these edge cases: [list]."

---

## Consistency Score Formula

```
consistency = 1 - (stddev / mean)
```

| Consistency | Interpretation |
|------------|----------------|
| > 0.95 | Excellent — skill produces nearly identical quality every time |
| 0.85 - 0.95 | Good — minor variations within acceptable range |
| 0.70 - 0.85 | Fair — noticeable differences between runs |
| < 0.70 | Poor — output quality is a coin flip |

**Edge case:** If mean is 0, consistency is 0 (the skill always fails, which is at least consistent).

---

## Minimum Run Counts for Statistical Significance

With 3 runs, you can detect gross inconsistency (stddev > 0.3) but can't distinguish fine-grained variance.

| Runs | Detects | Confidence |
|------|---------|------------|
| 3 | Gross inconsistency | Low — stddev estimate unreliable |
| 5 | Moderate patterns | Medium — meaningful stddev |
| 10 | Subtle patterns | High — reliable confidence intervals |
| 20+ | Statistical significance | Research-grade |

**Recommendation:** Start with 3 runs for rapid iteration. Move to 5 runs for thorough evaluation. Use 10 runs only for production skills where consistency is critical.

---

## Using Variance to Prioritize Skill Improvements

1. **Sort dimensions by variance** (highest first)
2. **For each high-variance dimension**, read the transcripts from the worst-scoring run
3. **Identify the ambiguity** — what did Claude interpret differently?
4. **Fix the skill instructions** — make the ambiguous part explicit
5. **Re-run evals** — verify variance decreased

This is more effective than trying to raise the mean score directly. Reducing variance often raises the mean as a side effect (the "bad" runs get better).
