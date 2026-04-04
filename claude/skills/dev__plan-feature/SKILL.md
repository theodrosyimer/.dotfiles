---
name: plan-feature
description: Plan a feature using TDD. Explores the codebase, identifies affected modules, and produces a structured implementation plan with test cases. Does NOT write any code.
disable-model-invocation: true
context: fork
agent: Plan
argument-hint: "<feature description>"
allowed-tools: Read, Grep, Glob
---
ultrathink

Plan the implementation of: $ARGUMENTS

## Your task

1. **Understand the feature**: What is being asked? What are the acceptance criteria?
2. **Explore the codebase**: Read existing modules, understand the architecture, find related code
3. **Identify the boundary**: Which module/use case is this feature in? What are the ports and adapters?
4. **Design the test strategy**:
   - List each behavior that needs a test (one test = one behavior)
   - For each test, specify: test name, input, expected output, which fake/stub is needed
   - Tests should be at the handler boundary (sociable unit tests)
   - **Order tests by TPP**: sequence so each test requires only ONE step down the transformation priority list
5. **Design the implementation**: Which files need to change? In what order?
6. **Produce a structured plan** with:
   - Test file paths and test case names (in TPP-ordered sequence)
   - For each test, annotate the expected transformation: e.g., "Test 3: constant→scalar"
   - Implementation file paths and what changes

## References (all in this skill's references/)

- **Complexity assessment**: `references/crud-simple.md`, `references/cqrs-standard.md`, `references/cross-context.md`
- **Consistency classification**: `references/consistency-requirements.md` — STRONG | SESSION | EVENTUAL per data type
- **Architecture mapping**: `references/architecture-mapping.md` — CRUD/CQRS/CROSS_CONTEXT → implementation approach
- **PRD format & schema**: `references/prd-format.md` — PRD.json structure, content rules, traceability
- **PRD templates**: `assets/templates/prd-crud.json`, `prd-cqrs.json`, `prd-cross-context.json`
- **PRD examples**: `assets/examples/prd-parking-reservation.json`
- **PRD validation**: `scripts/validate-prd.ts`

## Constraints
- You are in read-only mode. Do NOT attempt to create or edit files.
- Follow hexagonal architecture: test through ports, fake the adapters
- Prefer ultra-light fakes (XxxRepositoryFake, SequentialIdProvider) over mocks (ADR-0016)
- One test = one behavior. No testing implementation details.
