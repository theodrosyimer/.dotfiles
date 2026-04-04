---
name: adr
description: Manage Architecture Decision Records (ADRs) for the project. Use this skill whenever
  the user discusses, proposes, or questions an architectural choice — even if they don't
  say "ADR" explicitly. Trigger on phrases like "should we use X or Y", "why did we choose",
  "let's switch from", "I'm thinking about changing", "what's the current approach for",
  "document this decision", or any architectural trade-off discussion. Also trigger when
  implementing a feature that contradicts or isn't covered by existing ADRs, or when a
  code review raises architectural questions. This skill creates, queries, supersedes,
  and maintains ADRs following the project's structured text diagram standard.
---

# Architecture Decision Records (ADR) Skill

## Overview

ADRs capture significant architectural decisions with their context, rationale, and consequences.
They serve as the **living record of the project's architectural state** — answering both
"what is the current architecture?" and "why is it this way?"

Writing ADRs serves two purposes: they act as a record for people months or years later to
understand why the system is constructed the way it is, and the act of writing them clarifies
thinking — surfacing different points of view and forcing resolution.

## ADR Location & Naming

```
docs/adr/
  0001-use-modular-monolith-architecture.md
  0002-type-driven-domain-modeling-with-zod-at-boundaries.md
  ...
  index.md                # Auto-generated decision log
```

**Naming convention**: `NNNN-lowercase-kebab-title.md` where NNNN is zero-padded sequential.

## When to Create an ADR

Create an ADR when:

- Choosing between architectural alternatives (framework, pattern, library, approach)
- Establishing a convention that affects multiple modules or team members
- Making a decision that would be costly to reverse
- Overriding or evolving a previous architectural decision
- A decision affects cross-cutting concerns (testing strategy, module boundaries, communication patterns)

Do NOT create an ADR for:

- Implementation details within a single feature
- Bug fixes or minor refactors
- Dependency version bumps (unless changing libraries entirely)

## Workflows

### 1. Create a New ADR

When the user makes or discusses an architectural decision:

1. Determine the next ADR number:

   ```bash
   ls docs/adr/*.md 2>/dev/null | grep -oP '\d{4}' | sort -n | tail -1
   ```

   If no ADRs exist yet, start at 0001.

2. Read the ADR template: `references/adr-template.md`

3. Fill in the template with:
   - **Title**: Short imperative phrase ("Use Vitest over Jest", not "Testing framework decision")
   - **Status**: `proposed` | `accepted` | `deprecated` | `superseded by [NNNN]`
   - **Confidence**: How certain we are given current knowledge, plus reevaluation triggers
   - **Context**: The forces at play — what problem prompted this decision
   - **Decision**: What was decided, stated clearly and directly
   - **Consequences**: Both positive and negative outcomes
   - **Alternatives Considered**: What else was evaluated and why it was rejected

4. Save to `docs/adr/NNNN-title.md`

5. Regenerate the index: read `references/index-generator.md` and follow the procedure.

### 2. Query Existing ADRs

When the user asks about current architectural decisions or before implementing something
that touches architecture:

1. Search existing ADRs:

   ```bash
   grep -rl "keyword" docs/adr/ 2>/dev/null
   ```

   Or read the index at `docs/adr/index.md` for an overview.

2. Read relevant ADRs and summarize the current architectural state for the user.

3. If no ADR covers the topic, suggest creating one.

### 3. Supersede an ADR

Once accepted, an ADR is **immutable** — never reopened, edited, or amended. If a decision
needs to change (even partially), create a new ADR that supersedes it. This maintains a
clear log of decisions and how long each one governed the work.

When a previous decision is being replaced:

1. Create the new ADR (following workflow 1) with context explaining why the previous decision is changing.
   The new ADR's Context section should reference the superseded ADR and explain what changed.

2. Update the old ADR's status:
   - Change `Status: accepted` to `Status: superseded by [NNNN-new-title]`
   - Add a note at the top linking to the new ADR.
   - This status update is the **only** permitted edit to an accepted ADR.

3. Regenerate the index.

## ADR Quality Checklist

Before finalizing any ADR, verify:

- [ ] Title is imperative and specific (not vague like "Database decision")
- [ ] Context explains the problem forces, not just "we needed to choose"
- [ ] Decision is stated directly — a reader knows exactly what to do
- [ ] Consequences include both positives AND negatives (no decision is free)
- [ ] Alternatives list at least one rejected option with clear rationale
- [ ] Confidence level is set with specific reevaluation triggers (not vague "if things change")
- [ ] Status is set correctly
- [ ] Cross-references to related ADRs are included where relevant
- [ ] Follows the project's structured text diagram standard for any architectural diagrams
- [ ] Total length ≤ 2 pages (~100 lines). If longer, move supporting material to References or linked docs
- [ ] Each section's first sentence carries the key point (inverted pyramid style)

### 4. Seed Initial ADRs (First-Time Setup)

When setting up ADRs for a new project, this skill includes pre-written seed ADRs in `seed/`.

1. Create the target directory:

   ```bash
   mkdir -p docs/adr
   ```

2. Copy all seed ADRs:

   ```bash
   cp seed/*.md docs/adr/
   ```

3. Review each seeded ADR with the user — adjust dates, deciders, and context to match the project.

4. Delete or archive the `seed/` directory after setup — it's a one-time bootstrap.

## Integration with Project Methodology

ADRs connect to the broader development workflow:

- **PRD phase**: When a PRD reveals an architectural question, create a `proposed` ADR
- **Implementation phase**: Reference accepted ADRs when making implementation choices
- **Code review**: If a PR contradicts an ADR, either update the PR or supersede the ADR
- **Retrospectives**: Review recent ADRs to capture lessons learned

## Structured Text Diagrams in ADRs

When an ADR needs architectural diagrams, follow the project's diagram standard
(NOT Mermaid). Use ASCII box diagrams with ✅/❌ rules:

```
DEPENDENCY DIRECTION:
  Component A → Component B → Component C

ALLOWED:
  ✅ A → B  (reason)
  ✅ B → C  (reason)

FORBIDDEN:
  ❌ C → A  (reason — violates X principle)
```
