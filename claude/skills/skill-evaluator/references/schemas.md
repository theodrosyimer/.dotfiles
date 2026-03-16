# JSON Schemas

This document defines the JSON schemas used by skill-evaluator. It extends the skill-creator schemas with structural assertions and quality rubrics.

---

## evals.json (Extended)

Defines the eval suite for a skill. Located at `evals/evals.json` within the skill directory.

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
      "name": "Descriptive Eval Name",
      "prompt": "The task to execute with the skill",
      "expected_output": "Human description of what success looks like",
      "files": ["evals/files/input.ts"],
      "structural_expectations": [
        {
          "id": "S1",
          "type": "file_exists",
          "description": "Test file created",
          "pattern": "*.test.ts",
          "critical": true
        }
      ],
      "quality_rubric": {
        "dimensions": [
          {
            "id": "Q1",
            "name": "dimension_name",
            "description": "What this measures and why it matters",
            "weight": 2.0,
            "scoring": {
              "1": "Description of score 1 (poor)",
              "3": "Description of score 3 (acceptable)",
              "5": "Description of score 5 (excellent)"
            }
          }
        ]
      }
    }
  ]
}
```

**Fields:**
- `skill_name`: Name matching the skill's frontmatter
- `eval_config`: Global configuration
  - `runs_per_eval`: Number of times to run each eval (default: 3)
  - `structural_gate`: If true, skip LLM judge when critical structural assertions fail
  - `judge_model`: Model ID for the LLM judge (should differ from executor model)
  - `baseline_comparison`: If true, also run without the skill for delta measurement
- `evals[].id`: Unique integer identifier
- `evals[].name`: Human-readable name (used in viewer headers)
- `evals[].prompt`: The task to execute
- `evals[].expected_output`: Human-readable description of success
- `evals[].files`: Optional list of input file paths (relative to skill root)
- `evals[].structural_expectations`: Layer 1 deterministic assertions (see below)
- `evals[].quality_rubric`: Layer 2 LLM judge dimensions (see below)

---

## Structural Expectations

Each structural expectation defines a deterministic check.

```json
{
  "id": "S1",
  "type": "file_exists",
  "description": "Human-readable description",
  "pattern": "*.test.ts",
  "critical": true
}
```

**Common fields:**
- `id`: Unique identifier within the eval (S1, S2, ...)
- `type`: Assertion type (see types below)
- `description`: What this checks (shown in reports)
- `critical`: If true, failing this assertion fails the structural gate

**Assertion types:**

| Type | Fields | Description |
|------|--------|-------------|
| `file_exists` | `pattern` | At least one file matches glob |
| `file_contains` | `pattern`, `match` or `match_any` or `match_regex` | File contains string/regex |
| `file_not_contains` | `pattern`, `match` or `match_any` or `match_regex`, `except_context[]` | File does NOT contain pattern |
| `no_errors` | — | No error patterns in transcript |
| `file_count` | `pattern`, `count`, `operator` (==, >=, <=) | Expected file count |
| `custom_script` | `script` | Run bash command, exit 0 = pass |

**Special fields for contains/not_contains:**
- `match`: Single string to search for
- `match_any`: Array of strings (any match = found)
- `match_regex`: Python regex pattern
- `except_context`: Array of context strings that exempt a match (e.g., allow `vi.fn()` near "onSubmit")

---

## Quality Rubric

Defines the LLM judge scoring dimensions.

```json
{
  "dimensions": [
    {
      "id": "Q1",
      "name": "tdd_philosophy",
      "description": "Tests focus on business behavior at use case boundary...",
      "weight": 2.0,
      "scoring": {
        "1": "Tests implementation details...",
        "3": "Tests outcomes but some coupling...",
        "5": "All tests validate business behavior..."
      }
    }
  ]
}
```

**Fields:**
- `dimensions[].id`: Unique identifier (Q1, Q2, ...)
- `dimensions[].name`: Machine-readable name (used in benchmark aggregation)
- `dimensions[].description`: Full description for the LLM judge
- `dimensions[].weight`: Relative weight in the weighted mean (higher = more important)
- `dimensions[].scoring`: Anchor descriptions for 1, 3, and 5 scores

---

## structural.json

Output from the structural checker (Layer 1). Located at `<run-dir>/structural.json`.

```json
{
  "expectations": [
    {
      "id": "S1",
      "text": "Test file created",
      "type": "file_exists",
      "passed": true,
      "evidence": "Found: create-booking.use-case.test.ts",
      "critical": true
    }
  ],
  "summary": {
    "passed": 5,
    "failed": 0,
    "total": 5,
    "pass_rate": 1.0
  },
  "gate_passed": true
}
```

**Fields:**
- `gate_passed`: If false, at least one critical assertion failed → skip LLM judge

---

## grading.json (Extended)

Output from the LLM judge (Layer 2). Extends skill-creator's grading.json with rubric scores.

```json
{
  "expectations": [
    {
      "text": "Uses fixture factory pattern",
      "passed": true,
      "evidence": "Found createBookingFixture() in test file line 12"
    }
  ],
  "summary": {
    "passed": 4,
    "failed": 1,
    "total": 5,
    "pass_rate": 0.80
  },
  "rubric_scores": {
    "tdd_philosophy": {
      "score": 4,
      "evidence": "Tests validate business outcomes (booking confirmed, price calculated) not implementation details. Minor: one test checks internal method."
    },
    "fake_driven_correctness": {
      "score": 5,
      "evidence": "InMemoryBookingRepository for repo, SequentialIdProvider for IDs, real PricingService."
    }
  },
  "rubric_summary": {
    "weighted_mean": 4.2,
    "max_possible": 5.0,
    "normalized": 0.84
  },
  "claims": [
    {
      "claim": "All business rules are tested",
      "type": "quality",
      "verified": false,
      "evidence": "Missing test for overlapping booking rejection"
    }
  ],
  "eval_feedback": {
    "suggestions": [
      {
        "assertion": "S7: Uses fixture factory pattern",
        "reason": "This checks for the pattern name but would pass even if the factory returns incorrect data. Consider checking that overrides are used."
      },
      {
        "reason": "No assertion checks whether domain services are REAL instances — this is a core principle that could be violated silently."
      }
    ],
    "overall": "Structural assertions cover syntax well but miss semantic correctness. Add assertions for domain service wiring."
  }
}
```

**New fields (vs skill-creator grading.json):**
- `rubric_scores`: Per-dimension scores from the LLM judge
  - `{dimension_name}.score`: Integer 1-5
  - `{dimension_name}.evidence`: Why this score was given
- `rubric_summary`: Aggregate rubric statistics
  - `weighted_mean`: Σ(score × weight) / Σ(weight)
  - `normalized`: weighted_mean / 5.0 (0-1 scale)

---

## benchmark.json (Extended)

Same schema as skill-creator's benchmark.json, with additional rubric aggregation.

The `run_summary` includes rubric dimension stats:

```json
{
  "run_summary": {
    "with_skill": {
      "pass_rate": {"mean": 0.85, "stddev": 0.05, "min": 0.80, "max": 0.90},
      "rubric_normalized": {"mean": 0.84, "stddev": 0.04, "min": 0.80, "max": 0.88},
      "overall_efficiency": {"mean": 0.845, "stddev": 0.03, "min": 0.80, "max": 0.88},
      "consistency": 0.96,
      "time_seconds": {"mean": 45.0, "stddev": 12.0, "min": 32.0, "max": 58.0},
      "tokens": {"mean": 3800, "stddev": 400, "min": 3200, "max": 4100},
      "rubric_dimensions": {
        "tdd_philosophy": {"mean": 4.2, "stddev": 0.4, "min": 4, "max": 5},
        "fake_driven_correctness": {"mean": 4.8, "stddev": 0.2, "min": 4, "max": 5}
      }
    }
  }
}
```

**New fields:**
- `rubric_normalized`: Aggregated rubric score (0-1) across runs
- `overall_efficiency`: Combined structural + rubric score
- `consistency`: 1 - (stddev / mean) of overall_efficiency
- `rubric_dimensions`: Per-dimension stats showing which areas are strong/weak and where variance is high

---

## eval_feedback_aggregate.json

Collected eval improvement suggestions across all runs and evals. Used for the self-improving loop.

```json
{
  "skill_name": "testing",
  "iteration": 1,
  "total_runs": 9,
  "suggestions": [
    {
      "frequency": 3,
      "assertion": "S7",
      "reason": "Checks pattern name but not semantic correctness",
      "action": "Add structural check for factory override usage"
    },
    {
      "frequency": 2,
      "assertion": null,
      "reason": "No assertion checks domain service wiring is real",
      "action": "Add file_not_contains for FakePricingService etc."
    }
  ]
}
```

Suggestions appearing in multiple runs (high frequency) are strong signals for eval improvement.
