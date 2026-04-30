# Prompt Anatomy — Structure of an Effective Reviewer Prompt

Every reviewer prompt follows a strict structure. Deviating from this structure
degrades review quality. The "What NOT to Flag" section is equally important as
"What to Flag" — without it, reviewers produce a firehose of speculative warnings
that engineers learn to ignore.

## Required Sections

```
REVIEWER PROMPT STRUCTURE

1. ROLE DECLARATION (1-2 sentences)
   "You are a {domain}-focused code reviewer for a {stack description}."
   → Anchors the model's expertise and vocabulary

2. WHAT TO FLAG (5-10 bullet points)
   → Specific, concrete issues within this reviewer's domain
   → Each bullet describes a pattern, not a vague concern
   → Ordered by severity (most dangerous first)

3. WHAT NOT TO FLAG (5-10 bullet points)
   → Equally specific exclusions
   → Prevents the most common false positive patterns
   → This section grows over time as false positives are identified

4. (Optional) SEVERITY GUIDANCE
   → When the same issue type can be different severities
   → Context-dependent severity rules
```

## Writing "What to Flag" Rules

```
GOOD — Specific and Actionable

  ✅ "SQL injection via raw SQL or template literals in Drizzle ORM queries"
  ✅ "Missing ownership checks allowing IDOR on user-specific endpoints"
  ✅ "N+1 query patterns: loops executing individual DB queries instead of batch"

BAD — Vague and Noise-Generating

  ❌ "Security vulnerabilities" (too broad — what kind?)
  ❌ "Performance issues" (meaningless without specifics)
  ❌ "Code quality problems" (everything is a quality problem)
  ❌ "Consider adding error handling" (where? what error?)
```

## Writing "What NOT to Flag" Rules

This is where false positives die. Every exclusion should be traceable to a real
false positive that occurred in production reviews.

```
EXCLUSION PATTERNS — Templates

SCOPE BOUNDARY:
  "Issues in unchanged code that this MR does not affect"
  "Architecture decisions that are consistent with existing codebase patterns"

ALREADY HANDLED:
  "Defense-in-depth suggestions when primary defenses are adequate"
  "Missing input validation when Zod schema validation exists at the boundary"

SPECULATIVE:
  "Theoretical risks that require multiple unlikely preconditions to exploit"
  "Performance concerns on code paths that aren't in hot paths"

STYLE/PREFERENCE:
  "Code formatting — that's the formatter's job"
  "Import ordering"
  "Minor naming suggestions where the current name is already clear"

TOOL SUGGESTIONS:
  "'Consider using library X' style suggestions"
  "Alternative implementation approaches when current is functionally correct"
```

## The Growth Pattern

A new reviewer starts with ~5 "What NOT to Flag" entries. Over weeks of use,
this grows to 10-15 as false positives are identified and excluded. This is
normal and expected — the exclusion list is a calibration dataset.

```
REVIEWER MATURITY LIFECYCLE

  Week 1:  5 exclusions, ~60% signal ratio (noisy)
  Week 4:  10 exclusions, ~75% signal ratio (usable)
  Week 8:  12-15 exclusions, ~85% signal ratio (calibrated)
  Week 12+: 15+ exclusions, ~90% signal ratio (mature)

  If signal ratio drops below 60%: reviewer needs significant tuning
  If signal ratio exceeds 95%: reviewer might be too conservative (missing real issues)
```

## Anti-Patterns in Reviewer Prompts

```
PROMPT ANTI-PATTERNS

  ❌ Mixing domains: Security reviewer also flagging code style
     → Each reviewer must stay in its lane

  ❌ Generic advice: "Consider adding tests"
     → Must specify WHICH test scenario is missing

  ❌ No negative scope: Missing "What NOT to Flag" entirely
     → Guarantees a firehose of noise from day one

  ❌ Too many rules: >15 "What to Flag" items
     → Model loses focus; prioritize the highest-value checks

  ❌ Contradictory rules: Flag X, but also don't flag X
     → Review for internal consistency after adding exclusions
```

[^1]: Ryan Skidmore — [Orchestrating AI Code Review at scale](https://blog.cloudflare.com/ai-code-review/)
