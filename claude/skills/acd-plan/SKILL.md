---
name: acd-plan
description: >
  Plan work using the Agent Delivery Contract specification from Agentic Continuous Delivery (ACD).
  Guides an interactive discovery loop to produce a structured specification with Intent, Behavior,
  Constraints, and Acceptance Criteria — scoped to thin vertical slices an agent can execute.
  Use this skill whenever the user says "plan this", "spec this out", "help me think through",
  "what should the spec look like", "write a spec", "plan the implementation", or wants to
  break down a feature/task into an agent-executable specification. Also trigger when the user
  has a vague idea and needs help turning it into a concrete, actionable plan.
---

# ACD Plan — Agent-Assisted Specification

Produce agent-executable specifications by guiding the user through a structured discovery loop. The goal is a self-contained document that any agent (or new team member) can pick up and implement without asking clarifying questions.

The specification covers the **next single unit of work** — a thin vertical slice, not an entire epic. If scoping takes more than ~15 minutes of human thought, the scope is too large and needs splitting.

## Reference

For the full ACD specification (all six artifacts, authority rules, validation checklist), read `references/agent-delivery-contract.md`. Consult it when you need to explain the framework to the user or when you're unsure about artifact definitions or authority precedence.

## The Discovery Loop

Walk the user through four phases. Move briskly — the goal is clarity, not ceremony.

### Phase 1: Initial Framing

Ask the user to state the outcome they want in 1-3 sentences. If they've already described it in the conversation, extract it — don't make them repeat themselves.

Restate it back as a testable hypothesis:

> "We believe **[change]** will result in **[outcome]** because **[reason]**."

Get confirmation before moving on.

### Phase 2: Deep-Dive Interview

Ask 3-5 high-signal questions to surface implicit knowledge the user hasn't stated. Focus on:

- **Domain definitions** — Are there terms that mean something specific in this codebase?
- **Data shapes** — What inputs/outputs are involved? What do they look like?
- **Failure modes** — What happens when things go wrong? What errors matter?
- **Trade-offs** — Are there competing concerns (speed vs correctness, simplicity vs flexibility)?
- **Boundaries** — What's explicitly out of scope?

Don't ask questions you can answer by reading the codebase — use Grep/Glob/Read to look things up yourself first. Only ask the human what you genuinely can't discover.

### Phase 3: Drafting

Synthesize everything into a structured specification document (format below). Present the full draft to the user.

### Phase 4: Stress-Test Review

Critique your own draft before the user even reads it. Look for:

- Vague language ("handle appropriately", "as needed", "etc.")
- Missing edge cases or error paths
- Implicit assumptions that aren't stated
- Contradictions between sections
- Acceptance criteria that can't be mechanically verified

Fix what you find, flag what needs the user's input.

---

## Specification Format

The output is a single markdown document with four sections. Each section has a specific purpose and owner.

```markdown
# [Feature/Change Title]

## Intent
<!-- WHY this change exists. Human-owned, highest authority. -->

**Problem:** [What's happening now that shouldn't be, or not happening that should be]

**Desired outcome:** [What the world looks like after this change]

**Rationale:** [Why this matters — business value, user pain, technical debt]

**Hypothesis:** We believe [change] will result in [outcome] because [reason].

## User-Facing Behavior
<!-- WHAT users observe. Human-owned. BDD scenarios. -->

Scenario: [descriptive name]
  Given [initial state]
  When [user action or system event]
  Then [observable outcome]

Scenario: [error/edge case name]
  Given [initial state]
  When [trigger condition]
  Then [expected behavior]

## Feature Description
<!-- HOW it's constrained. Engineering-owned. Architectural boundaries. -->

### Musts
- [Hard constraints that cannot be violated]

### Must Nots
- [Explicit prohibitions]

### Preferences
- [Soft guidelines — follow unless there's a good reason not to]

### Escalation Triggers
- [Conditions where the agent must stop and ask a human]

## Acceptance Criteria
<!-- DONE definition. Mechanically verifiable. -->

### Done Definition
- [ ] [Observable outcome an independent reviewer can verify without reading code]
- [ ] [Another verifiable outcome]

### Test Cases
| Input | Expected Output | Notes |
|-------|----------------|-------|
| [specific input] | [specific expected result] | [edge case?] |
```

---

## Authority Hierarchy

When sections conflict, higher-authority sections win:

1. **Intent** — defines the "why" (highest)
2. **User-Facing Behavior** — defines observable outcomes
3. **Feature Description** — defines architectural constraints
4. **Acceptance Criteria** — defines verification (lowest)

Implementation must satisfy all four. If an acceptance criterion contradicts the intent, the intent wins — flag the contradiction and fix the criterion.

## Task Decomposition

If the spec implies more than ~2 hours of implementation work, break it into sub-tasks:

- Each task has clear inputs, outputs, and module boundaries
- Tasks are independently executable (an agent can pick one up without completing the others first)
- Dependencies between tasks are explicit
- Each task maps to a verifiable acceptance criterion

Present tasks as a numbered list with estimated scope (small/medium/large) rather than time estimates.

## Conversation Flow

**First invocation:** Run the full discovery loop (Phases 1-4), produce the spec.

**Follow-up:** If the user says "refine this", "update the spec", or provides feedback, apply the critique-decide-refine cycle:

1. Take the user's feedback
2. Identify what changes in the spec
3. Present the updated sections (not the whole doc, unless it's short)
4. Stress-test the changes

**Splitting:** If during discovery you realize the scope is too large, say so early. Propose how to split it and ask which slice to spec first.

## What Makes a Good Spec

A spec is ready when:

- An agent receiving only this document can implement it without clarification requests (self-containment test)
- Every scenario has concrete inputs and observable outputs
- Constraints distinguish musts from preferences
- Acceptance criteria are mechanically verifiable
- No section uses vague language ("appropriate", "as needed", "properly")
- The hypothesis connects the change to a measurable outcome
