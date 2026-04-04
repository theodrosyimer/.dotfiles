# 0003. Use Fakes Over Mocks for Testing

**Date**: 2025-01-01

**Status**: superseded by [0016-use-ultra-light-test-fakes-over-intelligent-inmemory](0016-use-ultra-light-test-fakes-over-intelligent-inmemory.md)

> **Note**: This ADR's core principle (fakes over mocks, no mocking libraries) remains valid. What changed is the *type* of fake: ADR-0016 replaces intelligent InMemory fakes (Map storage, contract tests) with ultra-light fakes (test controls all data, no internal state). See ADR-0016 for the full rationale.

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high (at time of writing) — superseded by ADR-0016 which refines the fake strategy

**Reevaluation triggers**: N/A — superseded.

## Context

TDD is non-negotiable in the project. The testing strategy focuses on business behavior validation at the use case boundary (hexagonal architecture's application layer). Test speed directly impacts development velocity — slow tests break the RED-GREEN-REFACTOR cycle.

Traditional mocking (`jest.fn()`, `vi.fn()`) creates brittle tests coupled to implementation details. When you mock a repository's `save` method, you're testing *that save was called*, not *that the business behavior works*. Refactoring internals breaks mock-based tests even when behavior is preserved.

Key forces:
- Ultra-fast test execution required for TDD flow
- Tests must validate business behavior, not implementation details
- Refactoring safety — internal changes shouldn't break tests
- Tests serve as living documentation of system behavior
- Parallel frontend development needs consistent fake data

## Decision

**We will use fake implementations (in-memory adapters) instead of mocks for all infrastructure ports.**

Testing rules:

```
INFRASTRUCTURE PORTS (repos, APIs, providers):
  ✅ Use fakes (InMemoryRepo, SequentialIdProvider)
  ❌ Never use vi.fn() / jest.fn() for infrastructure

DOMAIN SERVICES (pure business logic):
  ✅ Use real implementations — they have no infrastructure dependencies
  ❌ Never fake domain services

QUERY USE CASES:
  ✅ Use stubs returning fixture data
  ❌ Never use fakes for query paths

SPIES:
  ✅ Allowed on real implementations when verifying side effects
  ❌ Never use standalone vi.fn() as implementation
```

Naming conventions for test doubles:
- `InMemoryListingRepository` — no suffix needed (unambiguous)
- `SequentialIdProvider` — no suffix needed (unambiguous)
- `FailingPaymentGatewayStub` — always suffixed with `Stub` (indicates intentional failure)
- Error maps use `ExpectedErrors` naming

Test data conventions:
- No floating literals in tests — always use factory functions
- Factory naming: `create` prefix + `Fixture` suffix (e.g., `createBookingFixture`)
- Fixtures' interfaces serve as shared contracts for frontend-first MVP and agentic parallel work

## Consequences

### Positive

- Ultra-fast test execution (microseconds, not milliseconds)
- Tests validate behavior, not implementation — safe refactoring
- Fakes implement real interfaces — compiler catches contract drift
- Same fakes power both tests and frontend development with fake containers
- Predictable data (SequentialIdProvider) makes assertions simple and deterministic
- No test flakiness from network, timing, or shared state issues

### Negative

- Must maintain fake implementations alongside real ones
- Fakes can drift from real behavior if not covered by contract tests
- In-memory implementations don't catch database-specific bugs (handled by minimal integration tests)

### Neutral

- Helper methods on fakes (`clear()`, `getAll()`) are useful for testing but don't exist on real implementations

## Alternatives Considered

### Alternative 1: Mock-Heavy Testing (vi.fn() / jest.fn())

Rejected because mocks couple tests to implementation details. `expect(repo.save).toHaveBeenCalledWith(...)` breaks when you refactor how data flows through the use case, even if the business behavior is unchanged. Mocks test *how*, fakes test *what*.

### Alternative 2: Testcontainers for All Tests

Rejected as primary strategy because container startup adds seconds per test suite. Used only for integration tests (5% of test effort). Fakes handle the 80% use case boundary testing at microsecond speed.

## References

- Martin Fowler: "Mocks Aren't Stubs" — https://martinfowler.com/articles/mocksArentStubs.html
- Project knowledge: Test Doubles vs Fixtures — see project `docs/explanation/testing/test-doubles-vs-fixtures.md`
- Related: [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md)
