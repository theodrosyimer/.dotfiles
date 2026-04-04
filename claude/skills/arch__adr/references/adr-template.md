# ADR Template

Use this exact structure for every ADR. Do not add or remove sections.

**Writing principle**: Follow inverted pyramid style — put the most important
information first in every section. A reader skimming only the first sentence
of each section should understand the decision.

```markdown
# NNNN. Title in Imperative Form

**Date**: YYYY-MM-DD

**Status**: proposed | accepted | deprecated | superseded by [NNNN-title](NNNN-title.md)

**Deciders**: [who was involved in this decision] <!-- project extension, not in Nygard's original -->

**Confidence**: high | medium | low — [brief justification]

**Reevaluation triggers**: [specific, observable conditions that should prompt revisiting this decision]

Confidence reflects how certain we are this is the right call given current knowledge.
Reevaluation triggers must be specific and observable — not vague "if things change."
Example: "Reevaluate if Drizzle drops Postgres support or if we exceed 50 tables."

## Context

Describe the forces at play: business requirements, technical constraints, team capabilities,
timeline pressure, existing architectural decisions that influence this one.

Be specific. "We needed a testing framework" is weak. "Our TDD workflow requires sub-second
test execution with fake-driven development, and Jest's module resolution conflicts with our
Turborepo monorepo package boundaries" is strong.

Reference related ADRs: "This decision builds on [ADR-0001](0001-title.md)."

## Decision

State the decision directly in imperative form.

**We will use X for Y.**

Follow with the key aspects of the decision — enough detail that a developer joining the
project knows what to do without reading the entire conversation history.

If the decision involves architectural rules, use the structured text diagram format:

ALLOWED:
  ✅ ...

FORBIDDEN:
  ❌ ...

## Consequences

### Positive

- What becomes easier, faster, or more reliable
- What constraints does this remove

### Negative

- What trade-offs are accepted
- What becomes harder or more constrained
- What new risks are introduced

### Neutral

- What changes but is neither clearly positive nor negative

## Alternatives Considered

### Alternative 1: [Name]

Brief description of the alternative and why it was rejected.

### Alternative 2: [Name]

Brief description and rejection rationale.

## References

- Links to relevant documentation, articles, or discussions
- Project knowledge: [Title](relative-path-to-docs-file) — internal knowledge docs
- Related: [ADR-NNNN](filename.md) — related ADR cross-references
- Links to PRDs or user stories that drove this decision
```
