# File Layout Conventions

skill-lab produces two categories of artifacts: **durable** (live with the skill) and **ephemeral** (session-scoped).

## Skill Directory (durable)

Created at the configured `skills_path` from SKILL.md:

```
<skills_path>/<skill-name>/
├── SKILL.md
├── evals/
│   ├── evals.json              ← execution eval suite
│   └── trigger-eval.json       ← trigger optimization eval set
├── references/
│   ├── knowledge.md            ← distilled source material (Phase 1)
│   └── ...                     (other references as needed)
├── scripts/                     (if needed)
└── assets/                      (if needed)
```

## Workspace Directory (ephemeral)

Session artifacts that don't need to persist with the skill:

```
<cwd>/.skill-lab-workspace/<skill-name>/<session-id>/
├── design-recommendation.md     ← Phase 2 output (cc:architect)
├── iterations/                  ← Phase 3+ eval results
│   ├── iteration-01/
│   │   ├── benchmark.json
│   │   └── benchmark.md
│   └── iteration-02/
│       ├── benchmark.json
│       └── benchmark.md
└── trigger-results/             ← description optimization results
    └── <timestamp>/
        ├── results.json
        └── report.html
```

Session IDs use the format `YYYYMMDD-HHMMSS` derived from the start time. Iteration directories are zero-padded for sequential ordering.
