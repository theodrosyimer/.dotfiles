# Skill Evaluator — First Run Handoff

## What This Is

A skill evaluation framework that measures whether a Claude skill produces correct, consistent output. It uses a **hybrid two-layer approach**:

1. **Structural Gate (Layer 1)**: Deterministic assertions (file exists? no banned patterns? correct naming?) — zero variance, instant feedback
2. **LLM Judge (Layer 2)**: Rubric-scored quality dimensions (1-5 scale) — measured for variance across N runs

## What's Already Built

Everything is in the `skill-evaluator/` directory:

- `scripts/run-eval-suite.py` — **The main runner**. Orchestrates: Sonnet executor → structural checker → Opus grader → aggregation
- `scripts/structural-checker.py` — Layer 1 deterministic assertions
- `scripts/sync-upstream.py` — Keeps bundled scripts fresh from skill-creator
- `assets/templates/testing-evals.json` — 3 eval cases for the `testing` skill
- `references/` — Schemas, rubric templates, grader prompts, variance analysis guide
- `agents/` — Grader/comparator/analyzer prompts (bundled from skill-creator)
- `eval-viewer/` — HTML report generator (bundled from skill-creator)

## What Needs to Happen Now

### Step 1: First eval run against the `testing` skill

```bash
cd /path/to/skill-evaluator

# Dry run first — verify everything parses
python scripts/run-eval-suite.py \
    --eval-suite assets/templates/testing-evals.json \
    --skill-path /path/to/testing-skill \
    --dry-run

# Real run — 3 runs per eval (minimum for variance)
python scripts/run-eval-suite.py \
    --eval-suite assets/templates/testing-evals.json \
    --skill-path /path/to/testing-skill \
    --runs 3 --verbose
```

**Model allocation** (no API cost — uses Claude Code subscription):
- Executor: `claude-sonnet-4-6-20250514` (generates test code following the skill)
- Grader: `claude-opus-4-6` (scores rubric dimensions)

### Step 2: Debug the runner (expect this)

The `run-eval-suite.py` was built against `claude -p --output-format stream-json` based on skill-creator's `run_eval.py` patterns. But I couldn't test actual `claude` CLI invocations in the environment where it was built. **Likely adjustments needed**:

- **File capture**: The tool names for file creation might differ (`Write` vs `write_file` vs `EditTool`). Check `raw_events` in `_result.json` to see actual tool names and update `run_claude()` accordingly.
- **Working directory**: `claude -p` might not respect `cwd` for file output. If files land in the wrong place, adjust the executor to include explicit path instructions in the prompt.
- **Grader JSON parsing**: The grader might wrap JSON in markdown fences or add preamble. `parse_grader_json()` handles common cases but may need tuning.

### Step 3: Review results and calibrate

After the first successful run, check:

1. **`eval-results/<timestamp>/benchmark.json`** — aggregated scores and variance
2. **`eval-results/<timestamp>/<eval-id>/run_001/_structural.json`** — did structural assertions fire correctly?
3. **`eval-results/<timestamp>/<eval-id>/run_001/_grading.json`** — are rubric scores reasonable?
4. **`eval-results/<timestamp>/<eval-id>/run_001/*.test.ts`** — look at actual generated code

**Calibration questions**:
- Are structural assertions catching the right things? (check `_structural.json`)
- Are rubric scoring anchors well-calibrated? (1s should be bad, 5s should be excellent)
- Is the grader providing useful evidence citations?
- Is `eval_feedback` surfacing useful suggestions?

### Step 4: Iterate on eval quality

The grader produces an `eval_feedback` field with suggestions to improve the eval itself. After 3+ runs, check `benchmark.json` → `eval_feedback_summary` for high-frequency suggestions.

## Architecture Decisions

- **Sonnet executes, Opus grades** — measures realistic scenario (can a mid-tier model follow the skill?), grading is the harder task requiring nuance
- **Structural gate before LLM judge** — saves grader tokens when output is fundamentally broken
- **Per-dimension variance** — more actionable than overall score (high variance on `tdd_philosophy` but low on `fixture_pattern` → TDD instructions are ambiguous)
- **All via `claude -p`** — no API key needed, uses subscription

## Scoring Model

```
Overall Efficiency = (structural_pass_rate × 0.4) + (rubric_normalized × 0.6)
Consistency = 1 - (stddev / mean)
Final Grade = efficiency × consistency
```

Variance thresholds: `<0.5 stddev` = reliable, `0.5-1.0` = inconsistent, `>1.0` = unreliable.

## Key Files to Read First

1. `scripts/run-eval-suite.py` — understand the orchestration flow
2. `assets/templates/testing-evals.json` — see the eval format (3 test cases)
3. `references/structural-assertion-types.md` — the 6 assertion types available
4. `references/rubric-templates.md` — reusable quality dimensions
