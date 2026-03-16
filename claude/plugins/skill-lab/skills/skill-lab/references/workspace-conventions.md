# Workspace Conventions

Each skill-lab session creates a workspace directory in the current working directory:

```
<cwd>/skill-lab-workspace/<session-id>/
├── knowledge.md              ← Phase 1: yt-transcript output
├── design-recommendation.md  ← Phase 2: cc:architect classification + recommendation
├── skill/                    ← Phase 2: scaffolded skill directory
│   ├── SKILL.md
│   ├── references/           (if needed)
│   ├── scripts/              (if needed)
│   └── assets/               (if needed)
└── eval-results/             ← Phase 3: skill-evaluator output
    ├── evals.json
    └── <timestamp>/
        ├── benchmark.json
        └── benchmark.md
```

Session IDs use the format `YYYYMMDD-HHMMSS` derived from the start time.
