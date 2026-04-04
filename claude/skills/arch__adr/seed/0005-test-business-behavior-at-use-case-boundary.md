# 0005. Test Business Behavior at Use Case Boundary

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — validated across Booking and Listing modules with consistent test speed and refactoring safety

**Reevaluation triggers**: Integration test failures that sociable unit tests consistently miss; team adopts a framework (e.g., Effect) that changes the natural testing boundary; 80/15/5 ratio proves wrong — component tests catching more bugs than expected.

## Context

The project follows TDD strictly, but the *where* of testing matters as much as the *whether*. Testing at the wrong boundary creates either brittle tests (too low — testing implementation details) or slow tests (too high — testing through GUI or HTTP).

The hexagonal architecture provides a natural testing boundary: the application service layer (use cases). This is where business behavior is orchestrated, where acceptance criteria manifest as executable code, and where fake infrastructure can be injected for speed.

Key forces:
- Acceptance criteria from PRDs/user stories need executable validation
- Tests must run in milliseconds for TDD flow
- Business behavior is the primary testing concern, not technical wiring
- GUI testing is slow, brittle, and tests presentation rather than business logic
- Integration tests are necessary but should be minimal

## Decision

**We will test business behavior primarily at the use case (application service) boundary using sociable unit tests with fake infrastructure.**

Testing effort distribution:

```
USE CASE / ACCEPTANCE TESTS (80% effort):
  ✅ Business behavior validation through use cases
  ✅ Edge cases and error conditions
  ✅ Domain entities tested indirectly through use case flows
  ✅ Fake infrastructure for ultra-fast execution

COMPONENT CONTRACT TESTS (15% effort):
  ✅ UI behavior only — form submissions, conditional rendering
  ✅ Verify components call correct callbacks with correct data
  ❌ No business logic testing — that's at use case level

INTEGRATION / E2E TESTS (5% effort):
  ✅ Critical user flows only (registration, payment, core booking)
  ✅ Technical validation — full stack wires correctly
  ❌ Not for business rule validation — covered at use case level
```

"Sociable" means:
- Use cases call **real domain services** (they're pure business logic, no fakes needed)
- Use cases use **fake infrastructure ports** (repos, external APIs, providers)
- Domain entities are tested **indirectly** through use case behavior, not in isolation
- The test boundary is the use case's `execute()` method

```typescript
// This is the primary testing pattern (ADR-0016: each test wires its own fakes)
describe('Feature: Create Booking', () => {
  let spaceRepo: SpaceRepositoryFake
  let bookingRepo: BookingRepositoryFake
  let createBookingUseCase: CreateBookingUseCase

  beforeEach(() => {
    spaceRepo = new SpaceRepositoryFake()
    bookingRepo = new BookingRepositoryFake()
    createBookingUseCase = new CreateBookingUseCase(
      spaceRepo, bookingRepo, new SequentialIdProvider()
    )
  })

  it('should create confirmed booking for available space', async () => {
    // Inject — test controls what the fake returns
    spaceRepo.spaceToReturn = createSpaceTest({ status: 'available' })

    await createBookingUseCase.execute({
      spaceId: spaceRepo.spaceToReturn.props.id,
      startTime: tomorrow10am,
      endTime: tomorrow12pm,
    })

    // Inspect — test checks what the use case saved
    expect(bookingRepo.savedBooking).toBeDefined()
    expect(bookingRepo.savedBooking!.props.status).toBe('confirmed')
  })
})
```

### Test Structure: Per-Slice Test Drivers

Each handler slice has a co-located **test driver** class (`*.driver.ts`) that encapsulates
handler wiring (event store, clock, handler instantiation). Tests use the driver with
expressive method names — `given*` for setup, action verbs for the slice under test:

```typescript
// confirm-booking.driver.ts
export class ConfirmBookingTestDriver {
  readonly eventStore = new BookingEventStoreFake()
  private readonly clock = new SystemClock()
  bookingId!: string

  async givenRequestedBooking(overrides?: Partial<RequestBookingDTO>): Promise<void> {
    const dto = createRequestBookingDTOFixture(overrides)
    this.bookingId = dto.bookingId
    await new RequestBookingCommandHandler(this.eventStore, this.clock).execute(dto)
  }

  async confirmBooking(bookingId: string): Promise<void> {
    await new ConfirmBookingCommandHandler(this.eventStore, this.clock).execute({ bookingId })
  }

  async getEvents(bookingId: string) {
    return this.eventStore.getEvents(bookingId)
  }
}
```

### Test Structure: Assertion Granularity

Each `it()` block should verify **one facet** of the outcome. For independent assertions,
use a nested `describe` with a **scoped helper function** (no mutable `let` + `beforeEach`):

```typescript
describe('ConfirmBookingCommandHandler', () => {
  let driver: ConfirmBookingTestDriver

  beforeEach(() => {
    driver = new ConfirmBookingTestDriver()
  })

  it('should confirm a requested booking', async () => {
    await driver.givenRequestedBooking()
    await driver.confirmBooking(driver.bookingId)

    const events = await driver.getEvents(driver.bookingId)
    expect(events).toHaveLength(2)
    expect(events[1]?._tag).toBe('BookingConfirmed')
  })

  describe('when booking does not exist', () => {
    const NON_EXISTENT_BOOKING_ID = '019424a2-97e4-7000-8099-000000000099'

    async function confirmNonExistentBooking() {
      return driver.confirmBooking(NON_EXISTENT_BOOKING_ID).catch((e) => e)
    }

    it('should throw ApplicationException with domain message', async () => {
      const error = await confirmNonExistentBooking()
      expect(error).toBeInstanceOf(ApplicationException)
      expect(error.message).toBe('Cannot ConfirmBooking: no booking exists yet')
    })

    it('should wrap DomainError as cause', async () => {
      const error = await confirmNonExistentBooking()
      expect(error.cause).toBeInstanceOf(DomainError)
    })
  })
})
```

Rules:
- **Nest one level only** — never `describe` inside `describe` inside `describe`
- **Dependent assertions stay together** — null check + field access, length check + index access
- **Independent assertions split** — error type vs cause chain, different object properties
- **Scoped helper functions over `beforeEach`** — no mutable `let` bindings in nested describes
- **Named constants for test data** — `NON_EXISTENT_BOOKING_ID`, not magic strings
- **Applies to handler tests** — domain tests using the test DSL follow their own structure

## Consequences

### Positive

- Tests directly validate acceptance criteria from user stories
- Millisecond execution enables true RED-GREEN-REFACTOR flow
- Refactoring internals doesn't break tests (behavior-focused)
- Domain model emerges naturally from behavioral tests
- Each test wires its own ultra-light fakes — no shared container (ADR-0016)

### Negative

- Doesn't catch database-specific issues (handled by 5% integration tests)
- Doesn't validate GUI rendering (handled by 15% component tests + manual QA)
- Requires discipline to not test implementation details

### Neutral

- Test files co-locate with features in vertical slices

## Alternatives Considered

### Alternative 1: GUI-Level Acceptance Testing (Selenium/Cypress)

Rejected as primary strategy. GUI tests are slow (seconds per test), brittle (break on UI changes), and test presentation concerns mixed with business logic. Used only for critical E2E flows.

### Alternative 2: Unit Testing Domain Entities in Isolation

Rejected as primary strategy. Testing entities in isolation misses the orchestration behavior that use cases provide. Entities are tested indirectly through use case tests, which validates them in their real usage context.

### Alternative 3: Testing at Controller/API Level

Rejected because it adds HTTP serialization/deserialization overhead without testing additional business behavior. Use case boundary tests cover the same behavior faster.

## References

- Dave Farley: "Acceptance Testing" — Continuous Delivery channel
- Project knowledge: What Are Commit Tests? — see project `docs/explanation/testing/commit-tests.md`
- Related: [ADR-0003](0003-use-fakes-over-mocks-for-testing.md)
