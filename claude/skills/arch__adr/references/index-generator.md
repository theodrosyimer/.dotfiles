# Index Generator

Regenerate `docs/adr/index.md` after every ADR creation, supersession, or status change.

## Procedure

1. Read all ADR files in `docs/adr/` (excluding index.md itself)
2. Extract from each: number, title, date, status
3. Generate the index in this exact format:

```markdown
# Architecture Decision Records

This log captures all architectural decisions for the project.
Each record documents the context, decision, and consequences of a significant choice.

| # | Decision | Date | Status |
|---|----------|------|--------|
| [0001](0001-title.md) | Title text | YYYY-MM-DD | accepted |
| [0002](0002-title.md) | Title text | YYYY-MM-DD | accepted |
| [0003](0003-title.md) | Title text | YYYY-MM-DD | superseded by [0005](0005-title.md) |

## Statistics

- **Total decisions**: N
- **Accepted**: N
- **Superseded**: N
- **Proposed**: N
- **Deprecated**: N

## How to Use

- **Before implementing**: Search for ADRs related to your feature area
- **During code review**: Verify implementation aligns with accepted ADRs
- **When questioning a choice**: Read the ADR's context and alternatives before proposing changes
- **To change a decision**: Create a new ADR that supersedes the existing one
```

4. Write the generated content to `docs/adr/index.md`
