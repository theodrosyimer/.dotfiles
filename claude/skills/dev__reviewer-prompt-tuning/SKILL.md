---
name: reviewer-prompt-tuning
description: >-
  Tune AI code reviewer prompts by processing false positives, calibrating severity,
  and refining "What NOT to Flag" exclusion boundaries. Use this skill when the user
  says "false positive", "reviewer too noisy", "tune reviewer", "wrong severity",
  "shouldn't have flagged", "add exclusion", "calibrate reviewer", or reports that
  a specific reviewer is producing unhelpful findings. Also trigger when analyzing
  review output quality or when the user pastes a review finding they disagree with.
---

# Reviewer Prompt Tuning

Refine AI code reviewer prompts to maximize signal and minimize noise. The "What NOT
to Flag" sections are where 80% of ongoing review quality comes from — this skill
manages that process systematically.

## Skill Contents

```
reviewer-prompt-tuning/
├── SKILL.md                              ← You are here
└── references/
    ├── prompt-anatomy.md                 ← Structure of an effective reviewer prompt
    ├── severity-calibration.md           ← When to use each severity level
    └── false-positive-patterns.md        ← Common noise patterns and exclusions
```

**Before making changes, read the relevant reference file.** They define the quality bar.

---

## Workflow: Process a False Positive

### Step 1 — Identify the Finding

The user provides a false positive. Extract:
1. **Which reviewer** produced it (security, code-quality, architecture, etc.)
2. **The finding text** — what was flagged
3. **The file and line** — where it was flagged
4. **Why it's false** — the user's reasoning for why it shouldn't have been flagged

If any of these are missing, ask the user to provide them.

### Step 2 — Read the Current Prompt

Locate the reviewer's prompt file:
- **Subagent**: `.claude/agents/{reviewer-name}-reviewer.md`
- **CI**: `src/reviewers/{reviewer-name}.ts`

Read the current "What to Flag" and "What NOT to Flag" sections.

### Step 3 — Classify the False Positive

Determine the root cause:

```
FALSE POSITIVE CLASSIFICATION

SCOPE CREEP:
  Reviewer flagged something outside its domain
  → Fix: Add exclusion to "What NOT to Flag"

SEVERITY INFLATION:
  Issue is real but severity is wrong (critical → should be suggestion)
  → Fix: Add severity guidance to prompt, see references/severity-calibration.md

CONTEXT BLINDNESS:
  Reviewer didn't understand the surrounding code / project conventions
  → Fix: Add context rule (e.g., "This project uses X pattern, don't flag it")

SPECULATIVE FLAG:
  Theoretical risk requiring unlikely preconditions
  → Fix: Already covered by shared rules, but add specific exclusion if recurring

ALREADY HANDLED:
  Code already addresses the concern (error handling exists, validation present)
  → Fix: Add "Don't flag X when Y is already present" exclusion
```

### Step 4 — Draft the Exclusion

Write a precise "What NOT to Flag" bullet point. Rules for good exclusions:

```
EXCLUSION QUALITY RULES

  ✅ Specific: "Missing rate limiting on GET endpoints that return public data"
  ❌ Vague: "Don't flag rate limiting issues"

  ✅ Conditional: "Defense-in-depth suggestions when primary defenses are adequate"
  ❌ Blanket: "Don't suggest security improvements"

  ✅ Bounded: "N+1 patterns in seed/migration files"
  ❌ Overbroad: "Don't flag N+1 queries"
```

### Step 5 — Apply to Both Sources

Update the exclusion in BOTH locations to keep them in sync:

1. **Subagent file**: `.claude/agents/{reviewer-name}-reviewer.md`
   - Add the exclusion under `## What NOT to Flag`

2. **CI reviewer file**: `src/reviewers/{reviewer-name}.ts`
   - Add the exclusion in the `systemPrompt` string under `## What NOT to Flag`

Use `str_replace` for surgical edits — never recreate the entire file.

### Step 6 — Log the False Positive

Append to `docs/review-calibration/false-positives.log.md`:

```markdown
## YYYY-MM-DD — {reviewer-name}

**File**: `path/to/file.ts:42`
**Finding**: {the false positive finding text}
**Classification**: {scope-creep | severity-inflation | context-blindness | speculative | already-handled}
**Why false**: {user's reasoning}
**Exclusion added**: "{the exclusion text}"
```

Create the file and directory if they don't exist.

---

## Workflow: Bulk Calibration

When the user provides multiple review outputs or asks to calibrate a reviewer:

1. Read ALL findings from the specified reviewer
2. Categorize each as: true positive, false positive, or debatable
3. For false positives, batch-process through the single false positive workflow
4. Calculate the signal ratio: `true_positives / total_findings`
5. Report the ratio and recommend whether the reviewer needs more exclusions

Target signal ratio: >80%. Below 60% means the reviewer needs significant tuning.

---

## Workflow: Severity Recalibration

When findings are real but wrong severity:

1. Read `references/severity-calibration.md`
2. Compare the finding against the severity definitions
3. If the prompt lacks severity guidance for this specific case, add it:
   ```
   ## Severity Guidance
   - Missing rate limiting on public GET endpoints: suggestion (not warning)
   - Missing rate limiting on auth endpoints: warning
   - Missing rate limiting on payment endpoints: critical
   ```
4. Update both subagent and CI files

---

## Reference File Triggers

Read these before specific operations:

- **First time tuning any reviewer** → read `references/prompt-anatomy.md`
- **Severity disagreement** → read `references/severity-calibration.md`
- **Not sure if something is a common pattern** → read `references/false-positive-patterns.md`
