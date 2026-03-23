# Agent Delivery Contract — Full Reference

This reference contains the complete ACD specification details. Read this when you need deeper context on artifact definitions, authority rules, or the agent-assisted specification workflow.

## Table of Contents
1. [The Six Artifacts](#the-six-artifacts)
2. [Authority Hierarchy](#authority-hierarchy)
3. [Critical Principles](#critical-principles)
4. [Agent-Assisted Specification Workflow](#agent-assisted-specification-workflow)
5. [Specification Validation Checklist](#specification-validation-checklist)

---

## The Six Artifacts

These artifacts are **pipeline inputs, not reference documents**. The pipeline and agents consume them mechanically during validation.

### 1. Intent Description
**Authority:** Highest | **Owner:** Human (non-negotiable)

The self-contained problem statement explaining what the change accomplishes and why, without prescribing how. An agent receiving only this document should understand the problem without asking clarifying questions.

Requirements:
- State the problem clearly
- Define what the change should accomplish
- Explain why it matters
- Include a testable hypothesis: "We believe [change] will result in [outcome] because [reason]"

Agents help by: identifying ambiguity, suggesting edge cases, simplifying overly broad scope, and stress-testing hypotheses before implementation begins.

### 2. User-Facing Behavior
**Authority:** Second | **Owner:** Human

Describes how the system behaves from the user's perspective as observable outcomes.

Requirements:
- Express as observable, external behaviors
- Use BDD scenarios with Given/When/Then structure
- Focus on outcomes users can perceive
- Exclude internal implementation details

Agents help by: generating initial Gherkin scenarios from intent descriptions, identifying missing scenarios around boundaries, failures, and concurrent access patterns.

### 3. Feature Description (Constraint Architecture)
**Authority:** Third | **Owner:** Engineering team

Specifies architectural constraints, dependencies, and trade-off boundaries.

Sections:
- **Musts:** Hard boundaries that cannot be violated
- **Must Nots:** Prohibitions and limitations
- **Preferences:** Soft guidelines for approach
- **Escalation Triggers:** Conditions requiring human decision-making

Prevents agents from modifying architectural decisions — agents implement within constraints.

Agents help by: suggesting architectural considerations, drafting non-functional requirements, and verifying consistency between technical constraints and user-facing behavior.

### 4. Acceptance Criteria
**Authority:** Fourth | **Owner:** Humans (criteria), agents (may generate test code)

Two parts:
- **Done Definition:** Observable outcomes independent reviewers could verify without seeing code
- **Evaluation Design:** Test cases with known-good outputs that catch regressions

Criteria must be decoupled from implementation (verify behavior, not internals) and faithful to specifications (exercise all aspects without omitting edge cases).

Connection to Intent: Acceptance criteria verify "does the code work?" while the intent hypothesis asks "did this achieve its purpose?" Criteria run on every commit; hypothesis validation occurs post-deployment.

### 5. System Constraints
**Authority:** Fifth | **Owner:** Organizational standards

Non-functional requirements, security policies, performance budgets, and rules applying globally. Must be explicitly stated because agents cannot infer organizational norms.

Categories: security policies, performance budgets, architectural rules, operational requirements, monitoring/logging standards.

### 6. Implementation
**Authority:** Lowest | **Owner:** Agent (generated), human (reviewed), or co-authored

The actual code. Must satisfy acceptance criteria, conform to feature description constraints, and achieve intent description goals. Requires human review before merging.

Human review focuses on: intent alignment, architectural conformance, complexity assessment, and maintainability — not merely test passage.

---

## Authority Hierarchy

When artifacts conflict, higher-priority artifacts override lower ones:

1. Intent Description — defines the "why"
2. User-Facing Behavior — defines observable outcomes
3. Feature Description — defines architectural constraints
4. Acceptance Criteria — pipeline-enforced requirements
5. System Constraints — global organizational rules
6. Implementation — must satisfy all above

**When an agent detects a conflict between artifacts, it cannot resolve that conflict by modifying the artifact it does not own.** Without explicit authority definitions, agents guess wrong.

---

## Critical Principles

- Artifacts are **pipeline inputs consumed mechanically**, not reference documents for humans to browse
- Agents cannot modify artifacts they don't own — they escalate conflicts
- Human review of implementation goes beyond "do tests pass" to assess intent alignment and maintainability
- If specification effort for a single change takes more than 15 minutes, the change is too large — split it

---

## Agent-Assisted Specification Workflow

### Core Pattern
1. **Human drafts** — create initial version
2. **Agent critiques** — identify gaps, ambiguities, inconsistencies
3. **Human decides** — accept, reject, or modify suggestions
4. **Agent refines** — generate updated version incorporating decisions

### Scope Reality Check

"If your specification effort for a single change takes more than 15 minutes, the change is too large. Split it." Small-scope specification targets individual vertical slices of functionality, not entire feature sets.

### Discovery Loop

**Phase 1: Initial Framing**
State outcome, assign agent role as Principal Architect (interviewing, not taking orders), declare goal of creating agent-executable specification.

**Phase 2: Deep-Dive Interview**
Agent asks 3-5 high-signal questions to surface implicit knowledge: domain definitions, data schemas, failure modes, trade-offs.

**Phase 3: Drafting**
Agent synthesizes conversation into structured specification with all four stages and task decomposition.

**Phase 4: Stress-Test Review**
Agent critiques its own output for vagueness, missing constraints, confused areas for junior developers, and edge cases.

### Task Decomposition
Tasks are broken into sub-two-hour chunks using a planner-worker pattern with:
- Explicit module boundaries
- Clear inputs/outputs
- Independent executability

---

## Specification Validation Checklist

Before implementation begins, validate all artifacts together for:

- [ ] **Clarity** — No ambiguous language
- [ ] **Testability** — All outcomes are observable and verifiable
- [ ] **Scope** — No over-engineering; thin vertical slice
- [ ] **Terminology** — Consistent terms throughout
- [ ] **Completeness** — No implied behaviors without scenarios
- [ ] **Consistency** — No contradictions between sections
- [ ] **Hypothesis** — Change connects to measurable outcome
- [ ] **Self-containment** — Agent can implement without clarification

Sources:
- https://migration.minimumcd.org/docs/agentic-cd/specification/first-class-artifacts/
- https://migration.minimumcd.org/docs/agentic-cd/specification/agent-assisted-specification/
