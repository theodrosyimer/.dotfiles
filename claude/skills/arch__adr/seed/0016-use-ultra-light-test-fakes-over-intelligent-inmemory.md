# 0016. Use Ultra-Light Test Fakes Over Intelligent InMemory Implementations

**Date**: 2026-03-15

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — pattern validated across Booking and Listing modules with measurably faster TDD cycles

**Reevaluation triggers**: A module requires stateful fake behavior that cannot be expressed with inject/inspect fields (e.g., complex multi-entity queries); team grows and newcomers consistently struggle with the ultra-light pattern; integration test coverage becomes insufficient to catch mapping bugs.

## Context

[ADR-0003](0003-use-fakes-over-mocks-for-testing.md) established "fakes over mocks" as our test double strategy, using `InMemoryXxxRepository` implementations with `Map<string, Entity>` internal storage, `save()`, `findById()`, helper methods (`clear()`, `getAll()`), and contract tests to prove these fakes behave identically to real PostgreSQL adapters.

This approach is the Outside-in Diamond TDD pattern (Thomas Pierrain). It works, but introduces complexity that Michaël Azerhad identifies as unnecessary:

1. **Intelligent fakes are mini-databases.** `InMemoryListingRepository` with a Map, filtering, and helper methods is significant code to write and maintain. It has its own mapping subtleties — a bug in the fake is indistinguishable from a bug in the domain logic during acceptance tests.

2. **Contract tests exist only to prove Fake == Real.** This is a confidence layer that our integration tests on real secondary adapters already provide natively — without the intermediary of proving fake equivalence.

3. **Two types of fakes conflated into one class.** The same `InMemoryRepo` served both tests (where it should be inert) and frontend-first development demos (where stateful behavior is legitimate). These are radically different intentions that deserve separate implementations.

Key influences:
- Michaël Azerhad's teaching on ultra-light fakes (WealCome, TDD & Clean Architecture training)
- Uncle Bob's *The Little Mocker* — fakes are light, without internal values; stubs and spies handle most cases
- Azerhad's distinction: test fakes ≠ production demo fakes (different classes, different intentions)
- Ian Cooper's "TDD, Where Did It All Go Wrong" — test behavior at the use case boundary, not structure

This decision builds on [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md) (SUT = primary port) which remains unchanged.

## Decision

**We will use ultra-light test fakes that hold no internal state — the test controls all data, the fake does almost nothing.**

**We will drop contract tests — integration tests on real secondary adapters provide that confidence directly.**

### Test Fake Rules

```
ULTRA-LIGHT TEST FAKES:
  ✅ Fake records what the test passed in (e.g., savedBooking field)
  ✅ Fake returns what the test injected (e.g., bookingToReturn field)
  ✅ Fake may have very slight autonomy (e.g., position.contains('Paris')
     as impl of isInParis(position)) — Azerhad's threshold
  ✅ Fakes default to the absence variant of the ADT (ADR-0014)
  ❌ No internal Map/dictionary/collection storing multiple values
  ❌ No pre-filled data — everything injected by the test
  ❌ No helper methods like clear(), getAll(), reset()
  ❌ No filtering, sorting, or query logic in the fake

PRODUCTION DEMO FAKES (separate class, separate intention):
  ✅ CAN have Map storage, pre-filled data, filtering
  ✅ Used for frontend-first development, stakeholder demos
  ✅ Lives alongside test fakes but is a DIFFERENT class
  ❌ Never used in acceptance tests

SIGNAL THAT YOUR TEST FAKE IS TOO COMPLEX:
  ⚠️ It declares internal values (a Map, a dictionary, a list)
  ⚠️ It needs its own tests to verify correctness
  ⚠️ It reimplements repository logic (filtering, searching)
  → You're building an airplane when you need a scooter
```

### Naming Conventions (Updated from ADR-0003)

```
TEST FAKES (ultra-light):
  BookingRepositoryFake         — suffix Fake, no InMemory prefix
  ListingRepositoryFake         — suffix Fake
  PaymentGatewayFake            — suffix Fake

DEMO FAKES (stateful, for frontend dev):
  InMemoryBookingRepository     — InMemory prefix signals stateful impl
  InMemoryListingRepository     — used in frontend DI container, not in tests

UNCHANGED:
  SequentialIdProvider          — already ultra-light (counter, no state)
  FixedDateProvider             — already ultra-light (returns injected value)
  FixedClockStub                — already ultra-light (returns injected time)
  PaymentGatewayFailingStub     — always suffixed (throws typed errors)
  GetListingsUseCaseStub        — always suffixed (returns fixture data)
  ExpectedErrors                — error map naming unchanged
```

### Test Pattern (with ADT return types)

Fakes use ADT injection — the default is the absence variant:

```typescript
// Fake class structure with ADT defaults
export class ListingRepositoryFake implements ListingRepository {
  findByIdResult: FindListingResult = noListing   // ADT default: absence
  savedListing: ListingEntity | undefined = undefined

  async findById(_id: string): Promise<FindListingResult> {
    return this.findByIdResult
  }

  async save(entity: ListingEntity): Promise<void> {
    this.savedListing = entity
  }
}

// Test injects return values, asserts on what was passed to save
const repo = new ListingRepositoryFake()
repo.findByIdResult = listingFound(createListingFixture())

const idProvider = new SequentialIdProvider()
const handler = new CreateListingCommandHandler(repo, idProvider)

const dto = createCreateListingDTOFixture()
await handler.execute(dto)

expect(repo.savedListing).toBeDefined()
expect(repo.savedListing!.props.status).toBe('draft')
```

### Port Justification

The narrow repository port's primary justification is the test seam, not persistence abstraction:

```
PORT JUSTIFICATION:

  ✅ Port provides the test seam for sociable unit tests (80% bucket)
  ✅ Port methods express domain intent (findById, save — not SQL operations)
  ✅ Drizzle adapter uses the Data Mapper at the boundary (ADR-0017)
  ❌ Port does NOT exist for "swapping databases" — that's abstraction theater
  ❌ Port does NOT own mapping logic — that's the Data Mapper's job
```

Without the port, the use case would depend on the ORM directly, and you cannot fake Drizzle for fast tests at the use case boundary. The port earns its existence through the test seam, not through persistence abstraction.

### Integration Strategy (Two Clear Levels)

```
LEVEL 1 — UNIT TESTS (fast, commit stage):
  SUT: Primary Port (use case execute/handle)
  Traverses: Real domain services + real entities
  Doubles: Ultra-light fakes for infra ports
  Covers: Business behavior, acceptance criteria

LEVEL 2 — INTEGRATION TESTS (targeted, CI pipeline):
  SUT: Secondary Adapter directly
  Traverses: Real DB via testcontainers
  Doubles: None (real implementations)
  Covers: DTO↔domain mapping, SQL subtleties, constraints, serialization

NO CONTRACT TESTS:
  ❌ No shared test factory running same cases against fake and real
  ❌ No proving Fake == Real (fakes are inert — nothing to prove)
  ✅ Each level has a clear, non-overlapping role
```

## Consequences

### Positive

- Simpler fakes — a few fields instead of Map + methods; written in seconds
- No contract test layer to maintain — fewer test files, less test infrastructure
- Fakes cannot hide bugs — they have no logic that could be wrong
- Clearer separation between test tooling and demo tooling
- Shorter TDD cycles — less fake infrastructure to set up before first RED
- Aligns with Uncle Bob's *Little Mocker* taxonomy (stubs and spies for most cases, fakes are rare)
- ADT defaults make absence explicit — `noListing` is clearer than `undefined`

### Negative

- Tests become slightly more verbose — must inject return values and assert on saved values explicitly rather than seeding and querying an InMemory store
- Lose the "holistic traversal" feeling of Diamond-style acceptance tests where save → read-back validates the whole chain in one test
- Demo fakes for frontend-first development must be maintained as separate classes
- Existing InMemory implementations in the Booking module must be migrated

### Neutral

- SequentialIdProvider, FixedDateProvider, FixedClockStub are already ultra-light — no change needed
- Stubs for query use cases (returning fixture data) are unchanged
- FailingStub pattern is unchanged
- 80/15/5 hierarchy is unchanged
- SUT = primary port is unchanged

## Alternatives Considered

### Alternative 1: Keep Diamond-Style Intelligent Fakes + Contract Tests

The current approach (ADR-0003). Rejected because:
- InMemory fakes with Map storage are mini-databases with their own mapping subtleties
- Contract tests add complexity to prove Fake == Real — confidence that integration tests already provide
- The fakes themselves can contain bugs that acceptance tests won't catch
- Azerhad: "C'est comme leur filer un avion alors qu'ils ont besoin d'une trottinette"

### Alternative 2: Mock-Heavy Testing (vi.fn() / jest.fn())

Still rejected for the same reasons as ADR-0003 — mocks couple tests to implementation details and test *how* instead of *what*.

### Alternative 3: James Shore's Testing Without Mocks (Nullable Infrastructure)

Considered — Shore's approach uses real infrastructure with nullability. We already adopted Shore's Nullables selectively for gateways ([ADR-0013](0013-adopt-nullables-selectively-for-infrastructure-gateways.md)). However, for repositories, ultra-light fakes remain simpler than nullable database connections. The two approaches coexist: Nullables for infrastructure gateways, ultra-light fakes for repositories.

## References

- Michaël Azerhad: LinkedIn exchange on Outside-in Diamond TDD (Nov 2024) — source of the decision
- Uncle Bob: *The Little Mocker* (2014) — https://blog.cleancoder.com/uncle-bob/2014/05/14/TheLittleMocker.html
- Michaël Azerhad: TDD & Clean Architecture training — https://wealcomecompany.com
- Ian Cooper: "TDD, Where Did It All Go Wrong" — https://www.youtube.com/watch?v=EZ05e7EMOLM
- Supersedes: [ADR-0003](0003-use-fakes-over-mocks-for-testing.md)
- Builds on: [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md) (unchanged — SUT = primary port)
- Coexists with: [ADR-0013](0013-adopt-nullables-selectively-for-infrastructure-gateways.md) (Nullables for gateways)
- Related: [ADR-0014](0014-keep-domain-layer-null-free-using-adt-read-models.md) (ADT return types)
- Related: [ADR-0017](0017-extract-data-mapper-as-standalone-concern.md) (Data Mapper owns mapping, not port)
