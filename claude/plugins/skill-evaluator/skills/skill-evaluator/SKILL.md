---
name: skill-evaluator
description: Evaluate skill efficiency by measuring output vs expected output with variance analysis. Use when the user wants to test a skill's quality, benchmark skill performance, create eval suites for skills, run structural assertions + LLM judge evaluation, measure consistency across runs, or compare with-skill vs without-skill baselines. Also use when phrases like "evaluate my skill", "test skill quality", "benchmark skill", "skill efficiency", "does my skill work", or "run evals" appear. Do NOT use for creating new skills (use skill-creator) or optimizing skill descriptions/triggering (use skill-creator's description optimization).
---

# Skill Evaluator

Evaluate skill efficiency using a **hybrid structural assertions + LLM judge** approach with variance analysis.

## Overview

This skill measures whether a skill produces the correct output for a given input — consistently. It combines deterministic structural checks (Layer 1) with LLM-judged quality scoring (Layer 2), run multiple times to measure variance.

```
Eval Prompt → Execute Skill → Structural Gate → LLM Judge → Aggregate → Report
                                  (Layer 1)       (Layer 2)    (variance)
```

**Two layers, one goal:**
- **Layer 1 (Structural)**: Binary PASS/FAIL assertions run as code — file exists? correct format? no banned patterns? Zero variance, instant feedback.
- **Layer 2 (LLM Judge)**: Rubric-scored quality dimensions (1-5 scale) — content accuracy, convention adherence, completeness. Measured for variance across N runs.

**Why two layers?** Structural assertions catch regressions instantly. If a skill stops producing the right file format, you know in milliseconds — no need to waste tokens on an LLM judge. The judge only fires when structural checks pass, handling the fuzzy quality dimensions that code can't assess.

## Portability & Upstream Dependencies

This skill is **fully self-contained** — it bundles all scripts and agent prompts needed to run evaluations. No external dependencies required beyond Python stdlib.

Several files are sourced from Anthropic's **skill-creator** skill (eval viewer, benchmark aggregation, agent prompts). These are bundled locally for portability but should be periodically synced to pick up upstream improvements.

### Checking for stale dependencies

```bash
python scripts/sync-upstream.py --check
```

This exits 1 if any bundled file hasn't been synced within the reminder interval (default: 30 days). **Run this at the start of any eval session** — the skill will remind you.

### Syncing from upstream

```bash
# Auto-detect skill-creator location (works in Claude.ai and Claude Code)
python scripts/sync-upstream.py --sync --auto-detect

# Or specify path explicitly
python scripts/sync-upstream.py --sync --skill-creator-path /mnt/skills/examples/skill-creator

# Preview changes first
python scripts/sync-upstream.py --diff --auto-detect
```

### How it works

`UPSTREAM_MANIFEST.json` tracks each bundled file's upstream source and last sync date. The sync script copies files from skill-creator, updates timestamps, and reports what changed. All synced files are standard Python stdlib — no pip installs needed.

### Adjusting the reminder interval

Edit `sync_reminder_days` in `UPSTREAM_MANIFEST.json` (default: 30 days).

## When to Use This Skill

- **Evaluate an existing skill** — measure output quality and consistency
- **Create an eval suite** — define test cases with structural + quality expectations
- **Benchmark with variance** — run N times, measure mean ± stddev
- **Compare with/without baseline** — prove the skill adds value
- **Regression testing** — detect quality drops after skill changes
- **Self-improving evals** — the grader critiques the eval assertions themselves

## Core Concepts

### Eval Suite Structure

Each skill's eval suite lives in an `evals/` directory as a sibling to the skill:

```
my-skill/
├── SKILL.md
├── references/
├── scripts/
└── evals/                          ← eval suite
    ├── evals.json                  ← test case definitions
    ├── files/                      ← input files for evals
    └── structural-checks.sh        ← deterministic assertion runner
```

Results go into a workspace directory:

```
my-skill-workspace/
└── iteration-1/
    ├── eval-1-command-use-case/
    │   ├── eval_metadata.json
    │   ├── with_skill/
    │   │   ├── run-1/
    │   │   │   ├── outputs/        ← skill output files
    │   │   │   ├── transcript.md   ← execution transcript
    │   │   │   ├── timing.json     ← duration + tokens
    │   │   │   ├── structural.json ← Layer 1 results
    │   │   │   └── grading.json    ← Layer 2 results
    │   │   ├── run-2/
    │   │   └── run-3/
    │   └── without_skill/
    │       ├── run-1/
    │       ├── run-2/
    │       └── run-3/
    ├── benchmark.json              ← aggregated stats
    └── benchmark.md                ← human-readable report
```

### evals.json Schema

See `references/schemas.md` for the complete schema. Key structure:

```json
{
  "skill_name": "testing",
  "eval_config": {
    "runs_per_eval": 3,
    "structural_gate": true,
    "judge_model": "claude-sonnet-4-5-20250929",
    "baseline_comparison": true
  },
  "evals": [
    {
      "id": 1,
      "name": "Descriptive Name",
      "prompt": "The task to execute",
      "expected_output": "Human description of success",
      "files": [],
      "structural_expectations": [
        {
          "id": "S1",
          "type": "file_exists",
          "pattern": "*.test.ts",
          "description": "Test file created",
          "critical": true
        }
      ],
      "quality_rubric": {
        "dimensions": [
          {
            "id": "Q1",
            "name": "dimension_name",
            "description": "What this measures",
            "weight": 2.0,
            "scoring": {
              "1": "Description of score 1",
              "3": "Description of score 3",
              "5": "Description of score 5"
            }
          }
        ]
      }
    }
  ]
}
```

## Workflow

### Step 0: Check Upstream Freshness

Before starting any eval session, verify bundled scripts are current:

```bash
python scripts/sync-upstream.py --check
```

If stale, sync first: `python scripts/sync-upstream.py --sync --auto-detect`

### Step 1: Define the Eval Suite

Create or use an existing `evals.json` with structural expectations and rubric dimensions. See `assets/templates/testing-evals.json` for a complete example.

### Step 2: Run the Eval Suite (Claude Code)

The runner script orchestrates everything — executor, structural checker, grader, and aggregation:

```bash
# Run all evals in suite, 3 runs each (quick check)
python scripts/run-eval-suite.py \
    --eval-suite assets/templates/testing-evals.json \
    --skill-path /path/to/testing \
    --runs 3 --verbose

# Single eval with 5 runs for variance analysis
python scripts/run-eval-suite.py \
    --eval-suite assets/templates/testing-evals.json \
    --skill-path /path/to/testing \
    --eval-id command-use-case-tdd \
    --runs 5 --verbose

# Dry run — see the plan without executing
python scripts/run-eval-suite.py \
    --eval-suite assets/templates/testing-evals.json \
    --skill-path /path/to/testing \
    --dry-run
```

**Model allocation** (default, no API cost):
- **Executor**: Sonnet (`claude-sonnet-4-5-20250929`) — generates code from skill
- **Grader**: Opus (`claude-opus-4-6`) — scores rubric dimensions

Override with `--executor-model` and `--grader-model` if needed.

**Output structure**:
```
eval-results/<timestamp>/
├── config.json                    # Reproducibility config
├── benchmark.json                 # Aggregated results + variance
├── <eval-id>/
│   ├── run_001/
│   │   ├── _prompt.md             # Executor prompt (reproducible)
│   │   ├── _executor_response.md  # Raw executor text
│   │   ├── _structural.json       # Structural check results
│   │   ├── _grader_prompt.md      # Grader prompt
│   │   ├── _grading.json          # Rubric scores
│   │   ├── _result.json           # Combined run result
│   │   └── *.test.ts              # Generated files
│   ├── run_002/
│   └── run_003/
```

Start by identifying 2-3 **coarse-grained** eval cases covering the skill's primary use cases. For each eval, define:

1. **Prompt** — a realistic task a user would give
2. **Structural expectations** — deterministic, scriptable checks (Layer 1)
3. **Quality rubric** — LLM-judged dimensions with 1-3-5 scoring anchors (Layer 2)

Consult `references/structural-assertion-types.md` for available assertion types.
Consult `references/rubric-templates.md` for reusable quality dimensions per skill category.

**Start coarse, refine to fine only for failing areas.** If a coarse eval consistently fails on a specific dimension, split that dimension into finer-grained evals.

Save to `evals/evals.json` in the skill directory.

### Step 2: Build the Structural Assertion Runner

The structural assertion runner is a script that checks Layer 1 expectations against output files. It produces `structural.json`:

```json
{
  "expectations": [
    {"id": "S1", "text": "Test file created", "passed": true, "evidence": "Found: create-booking.use-case.test.ts"},
    {"id": "S2", "text": "No Jest imports", "passed": true, "evidence": "Grep found 0 matches for jest patterns"}
  ],
  "summary": {"passed": 5, "failed": 0, "total": 5, "pass_rate": 1.0},
  "gate_passed": true
}
```

Use `scripts/structural-checker.py` — it reads the eval's `structural_expectations` and runs them against the outputs directory. Run it:

```bash
python scripts/structural-checker.py \
  --eval-file evals/evals.json \
  --eval-id 1 \
  --outputs-dir workspace/iteration-1/eval-1/with_skill/run-1/outputs/ \
  --output structural.json
```

If `gate_passed` is false and any `critical` assertion failed, skip the LLM judge for this run (saves tokens).

### Step 3: Run the LLM Judge (Layer 2)

The LLM judge uses the Grader agent pattern from skill-creator. It receives:
- The eval prompt and expected output
- The quality rubric with scoring anchors
- The output files and execution transcript
- The structural results (so it doesn't re-check what's already verified)

The judge produces an **extended grading.json** that includes rubric scores:

```json
{
  "expectations": [...],
  "summary": {...},
  "rubric_scores": {
    "tdd_philosophy": {"score": 4, "evidence": "Tests validate business outcomes..."},
    "fake_driven": {"score": 5, "evidence": "InMemoryListingRepository used..."}
  },
  "rubric_summary": {
    "weighted_mean": 4.2,
    "max_possible": 5.0,
    "normalized": 0.84
  },
  "claims": [...],
  "eval_feedback": {
    "suggestions": [...],
    "overall": "..."
  }
}
```

The `eval_feedback` field is where the **self-improving loop** lives — the grader critiques the eval assertions and suggests improvements. Collect these across runs and surface them in the report.

See `references/grader-prompt.md` for the complete LLM judge prompt template.

### Step 4: Execute All Runs

For each eval, for each configuration (with_skill, without_skill), for each run (1..N):

1. Execute the skill with the eval prompt
2. Run structural checker (Layer 1)
3. If structural gate passes → run LLM judge (Layer 2)
4. Capture timing data (duration_ms, total_tokens)

**Parallelism**: If subagents are available (Claude Code), spawn all runs in parallel. If not (Claude.ai), run sequentially.

**Baseline comparison**: Always run both with_skill and without_skill. The delta proves the skill adds value (not just "the output is good" but "the output is better because of the skill").

### Step 5: Aggregate and Analyze

Run the aggregation script from skill-creator:

```bash
python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
```

This produces `benchmark.json` with:
- **Per-configuration stats**: mean, stddev, min, max for pass_rate, time, tokens
- **Delta**: difference between with_skill and without_skill
- **Per-run details**: individual expectation results

Then analyze patterns. Read `references/variance-analysis.md` for what to look for:
- **High variance dimensions** → ambiguous skill instructions
- **Non-discriminating assertions** → pass 100% both with/without skill (useless)
- **Always-failing assertions** → broken eval or fundamental skill gap
- **Flaky assertions** → non-deterministic behavior (investigate)

### Step 6: Generate Report and Review

Launch the eval viewer from skill-creator:

```bash
python eval-viewer/generate_review.py <workspace>/iteration-N \
  --skill-name <name> \
  --benchmark <workspace>/iteration-N/benchmark.json \
  --static /tmp/eval_report.html
```

The viewer shows:
- **Outputs tab**: Click through each test case, see outputs, leave feedback
- **Benchmark tab**: Stats summary with pass rates, timing, per-eval breakdowns

### Step 7: Iterate

Based on feedback and benchmark data:
1. **Fix failing structural assertions** → usually means skill instructions are wrong
2. **Improve low-scoring rubric dimensions** → enrich skill instructions for that area
3. **Reduce high-variance dimensions** → make instructions more specific, add examples
4. **Act on eval_feedback** → improve the eval assertions themselves (self-improving loop)
5. **Refine granularity** → split coarse evals that consistently fail into finer ones

## Scoring Model

```
Overall Skill Efficiency:
  = (structural_pass_rate × 0.4) + (rubric_normalized × 0.6)

Consistency Score:
  = 1 - (stddev / mean)    [of overall scores across runs]

Final Grade:
  = efficiency × consistency  [penalizes high-variance even if mean is good]
```

### Interpreting Variance

| stddev | Interpretation | Action |
|--------|---------------|--------|
| < 0.1 | Reliable skill — consistent output | None needed |
| 0.1-0.3 | Some inconsistency — review dimensions | Tighten ambiguous instructions |
| > 0.3 | Unreliable — wildly different outputs | Major skill rewrite needed |

**Per-dimension variance is more actionable than overall.** High variance on `tdd_philosophy` but low on `fixture_pattern` means the TDD guidance is ambiguous while naming conventions are clear.

## Minimum Run Counts

| Context | Runs | Why |
|---------|------|-----|
| Quick sanity check | 3 | Catches gross inconsistencies |
| Thorough eval | 5 | Meaningful stddev |
| Production skill | 10 | Reliable confidence intervals |

## Quick Reference

### Available Structural Assertion Types

See `references/structural-assertion-types.md` for the full list. Common ones:

| Type | Description |
|------|-------------|
| `file_exists` | Output file matching glob pattern exists |
| `file_contains` | File contains expected string/regex |
| `file_not_contains` | File does NOT contain banned pattern |
| `no_errors` | No execution errors in transcript |
| `file_count` | Expected number of output files |
| `custom_script` | Run a custom validation script |

### Reusable Rubric Dimensions

See `references/rubric-templates.md` for templates per skill category. Common dimensions:

| Dimension | Description |
|-----------|-------------|
| `correctness` | Output contains accurate information |
| `completeness` | All requested elements present |
| `convention_adherence` | Follows skill's prescribed patterns |
| `instruction_fidelity` | How closely execution followed SKILL.md |
| `usability` | Output is usable as-is without manual fixes |

## Roadmap

Features to add to `run-eval-suite.py` when needed:

### Blind A/B Comparator
Compare two skill versions (v1 vs v2) without bias. The judge receives both outputs unlabeled and picks the better one per rubric dimension. Proves whether a skill change actually improved quality or just felt better. Add as `--compare` subcommand that takes two benchmark.json results.

### Post-Hoc Analyzer
Pattern detection across 10+ runs that raw aggregation misses: non-discriminating assertions (always pass regardless of skill quality), miscalibrated rubric anchors (high score but wrong code), time/token tradeoffs, and dimension correlations. Add as `--analyze` subcommand that reads benchmark.json and produces actionable recommendations.
