# Test Quality Desiderata

This reference helps dev__write-tests by providing a quality criteria checklist for validating test suite quality during the RED phase.

## The Four Macro Properties

Evaluate every test (and the suite as a whole) against these four properties. A good test suite scores well across all four.

### 1. FAST
- Tests execute quickly enough for tight TDD feedback loops
- Speed is a property of test design and infrastructure touched, not the "unit/integration" label
- Fakes and in-memory execution are the primary speed enablers

### 2. CHEAP
- Tests are inexpensive to write and maintain
- Brittle tests that break on every refactor are expensive regardless of granularity
- Classicist approach (test outcomes, not interactions) reduces maintenance cost
- Shared fixture factories (`createXxxFixture`) reduce authoring cost

### 3. PREDICTIVE
- Tests find interesting bugs before production
- Contract tests verify fakes and real adapters satisfy same interface
- Two-suite pattern: fake suite in commit stage, real infra in CI pipeline
- Don't duplicate business logic testing in the integration layer

### 4. DESIGN SUPPORT
- Tests document intent and enable refactoring
- Test-first (TDD/BDD) produces intent-driven tests that explain WHY
- Tests written after implementation tend toward larger granularity and heavy mocking
- This is the most underappreciated property and hardest for AI to replicate

## Properties Over Types

The test pyramid's lasting contribution: most tests should be fast and cheap. But debating "unit vs integration" is less useful than asking:

| Property | Question to Ask |
|----------|----------------|
| Fast? | Does it execute quickly enough for TDD cycles? |
| Cheap? | Is it inexpensive to write and maintain? |
| Predictive? | Does it find bugs that matter before production? |
| Design support? | Does it document intent and enable refactoring? |

## Mapping to Our Testing Hierarchy

### Handler / Acceptance Tests (80%)
- Fast: Yes (fakes, milliseconds)
- Cheap: Yes (classicist, no brittle mock setup)
- Predictive: Yes (full business logic chain)
- Design: Yes (intent-first, TDD-driven)

### Component Contract Tests (15%)
- Fast: Yes (RNTL, in-memory)
- Cheap: Yes (UI contracts only)
- Predictive: Yes (catches UI regressions)
- Design: Yes (verifies component API)

### Integration / E2E (5%)
- Fast: No (real DB, network)
- Cheap: No (infrastructure setup)
- Predictive: Yes (catches real adapter bugs)
- Design: Limited

The hierarchy emerges naturally from optimizing all four properties.

## Design Pressure: Tests Before vs After

**Tests FIRST (TDD/BDD):**
- Document intent before implementation exists
- Positive pressure toward usable, testable APIs
- Smaller, focused tests emerge naturally
- Refactoring supported by high-confidence test suite
- Tests explain WHY the code exists

**Tests AFTER:**
- Larger granularity tests
- Heavy mock usage to compensate for poor separation
- Brittle in the face of refactoring
- Tests explain WHAT the code does, not WHY
- Higher maintenance cost

## AI-Generated Tests Warning

AI tools can produce tests that are predictive, fast, and cheap. But they fail at design support because they cannot see customer/user perspective from implementation alone. Always review AI-generated tests for:
- Do they explain WHY the behavior exists?
- Are they written from user/customer perspective?
- Would they survive a refactoring of internals?

## Sources

- Emily Bache, "It's Time We Go Beyond The Test Pyramid" (2024)
- Mike Cohn, "Succeeding with Agile" (2009) -- original test pyramid
