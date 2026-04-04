# 0015. Capture Time in Imperative Shell via Clock Port

**Date**: 2026-03-14

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — all hidden `new Date()` calls eliminated; time-dependent tests now deterministic

**Reevaluation triggers**: Temporal API stabilizes and replaces `Date` as the project's time type; a framework-level middleware captures time before handlers run (making explicit Clock injection unnecessary); team adopts Effect which provides its own time abstraction.

## Context

The three core domain functions (`decide`, `evolve`, `project`) are documented as pure, deterministic
reducers — same inputs always produce same outputs. However, `decide` functions were calling
`new Date()` directly to timestamp events, introducing hidden side effects across modules.

This decision builds on [ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md),
which establishes that domain functions use exhaustive ADT dispatch and are pure functions, and on
[ADR-0003](0003-use-fakes-over-mocks-for-testing.md), which establishes fakes over mocks as the
testing strategy, and on [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md), which
establishes that business behavior is tested at the use case boundary.

Key forces:

- `new Date()` breaks the determinism contract — calling `bookingDecide` twice with the same inputs produces different `occurredAt` timestamps, making time-dependent assertions impossible in tests
- The existing `IdProvider` port in `shared/types.ts` already demonstrates the pattern of abstracting infrastructure concerns behind interfaces — time is the same category of concern
- Event-sourced systems derive state from events; `occurredAt` is a critical field in every event — if tests cannot control it, they cannot verify time-dependent business rules (e.g. "booking must be confirmed within 24 hours")
- The imperative shell (handler) already owns all other side effects (event store I/O, error translation) — time capture belongs there, not in the pure domain function
- Every future `decide` function added to any module faces the same question — the convention must be documented as cross-cutting

## Decision

**We will capture time in the imperative shell (handlers) via a `Clock` port, and stamp the
resulting `Date` value onto the command as `issuedAt` at command instantiation time.**

The `decide` function receives time through the command — its signature is `(command, state)` with
no separate time parameter. The command's `issuedAt` field is mapped to the event's `occurredAt`
field inside decide: `occurredAt: command.issuedAt`.

### Clock port convention

```
INFRASTRUCTURE PORT (core/clock/clock.ts):
  interface Clock {
    now(): Date
  }

IMPLEMENTATIONS:
  SystemClock  — production: delegates to new Date()
  FixedClock   — testing: mutable currentTime property for time control
```

### Where time is captured

```
IMPERATIVE SHELL (handlers, listeners):
  ✅ Receive Clock via constructor injection
  ✅ Call clock.now() when instantiating the command
  ✅ Command carries issuedAt — decide reads it from the command

COMMAND CLASSES (slice layer):
  ✅ static from(dto, now) — accepts time as second parameter
  ✅ Stores now as issuedAt on the command instance

REACT FUNCTIONS (cross-stream integration):
  ✅ Receive now: Instant as a parameter from the imperative shell
  ✅ Stamp issuedAt on generated commands

DOMAIN FUNCTIONS (decide, evolve, project):
  ✅ decide(command, state) — reads command.issuedAt for event timestamps
  ✅ Maps command.issuedAt → event.occurredAt
  ❌ Never call new Date() or any Clock method
  ❌ Never import Clock — domain functions have zero infrastructure dependencies
```

### Naming convention

- **`issuedAt`** on commands — when the command was issued/dispatched
- **`occurredAt`** on events — when the event occurred (derived from command.issuedAt in decide)

Commands are intentions; events are facts. The naming reflects this distinction.

### Concrete signatures

```ts
// command type — carries issuedAt
type ConfirmBookingCommand = {
  readonly _tag: 'ConfirmBooking'
  readonly bookingId: BookingId
  readonly issuedAt: Instant
}

// command class — from() accepts now
class RequestBookingCommand {
  static from(input: RequestBookingDTO, now: Instant): RequestBookingCommand
}

// decide — reads time from command, no separate now parameter
function bookingDecide(
  command: BookingCommand,
  currentState: BookingState,
): Result<BookingEvent[], DomainError>

// inside decide, the mapping:
//   occurredAt: command.issuedAt

// handler — stamps time at command instantiation
class RequestBookingCommandHandler {
  constructor(
    private readonly eventStore: EventStore<BookingEvent>,
    private readonly clock: Clock,
  ) {}

  async execute(input: RequestBookingDTO): Promise<void> {
    const command = RequestBookingCommand.from(input, this.clock.now())
    const events = await this.eventStore.getEvents(command.bookingId)
    const currentState = rebuildBookingState(events)
    const result = bookingDecide(command, currentState)
    // ...
  }
}

// react function — receives now from imperative shell
function spaceReactToBookingEvent(
  foreignEvent: BookingEvent,
  now: Instant,
): SpaceCommand[]

// listener — passes clock.now() to react
class BookingEventListener {
  async handleBookingEvent(bookingEvent: BookingEvent): Promise<void> {
    const localCommands = spaceReactToBookingEvent(bookingEvent, this.clock.now())
    for (const command of localCommands) {
      const result = spaceDecide(command, currentState)
      // ...
    }
  }
}
```

### Testing convention

```
DECIDE TESTS (pure function tests):
  ✅ Put issuedAt on the command fixture: { _tag: 'ConfirmBooking', bookingId, issuedAt: now }
  ✅ Use decideScenario DSL: decideScenario(bookingDecide).given(state).when(command).thenEvents(...)
  ❌ No Clock setup needed — decide is pure, time comes from the command

HANDLER TESTS (integration tests):
  ✅ Use SystemClock when time value doesn't matter (most handler tests)
  ✅ Use FixedClock when asserting on timestamps or time-dependent behavior
  ✅ Mutate FixedClock.currentTime mid-scenario to simulate time advancing
```

## Consequences

### Positive

- Decide functions are now **strictly pure** — zero side effects, zero infrastructure dependencies, fully deterministic
- Decide signature is minimal: `(command, state)` — no extra parameters
- Time-dependent business rules become testable — control `issuedAt` on the command fixture and assert on `occurredAt` values in events
- Consistent with the existing port pattern (`EventStore`, `IdProvider`) — `Clock` is another infrastructure concern abstracted behind an interface
- `FixedClock` with mutable `currentTime` enables multi-step time scenarios in integration tests without `vi.useFakeTimers()` global state pollution
- Clear semantic distinction: commands have `issuedAt`, events have `occurredAt`
- New contributors see the pattern in the handler constructor — `Clock` is an explicit dependency, not a hidden `new Date()` buried in domain logic

### Negative

- Every command handler constructor requires a `Clock` parameter — slightly more wiring at composition time
- Every command type carries an `issuedAt` field — slightly larger command objects
- Handler tests must instantiate a `Clock` even when they don't assert on time — minor boilerplate

### Neutral

- `evolve` and `project` are unaffected — they receive time from events (already captured by decide), not from the clock
- The `Date` type itself is not abstracted — domain types still use `Date` for timestamps, which is adequate until the Temporal API stabilizes

## Alternatives Considered

### Alternative 1: `vi.useFakeTimers()` (global timer mocking)

Use Vitest's built-in fake timer support to mock `Date` globally in tests.

Rejected because it introduces global mutable state that leaks between tests, requires explicit `vi.useRealTimers()` cleanup, and contradicts [ADR-0003](0003-use-fakes-over-mocks-for-testing.md) which establishes fakes over mocks. It also doesn't make the side effect visible — `new Date()` still lives inside the "pure" function, hiding the dependency.

### Alternative 2: Clock port injected into decide

Pass a `Clock` interface to decide: `bookDecide(command, state, clock)`. The domain function calls `clock.now()` internally.

Rejected because it makes the dependency explicit but doesn't achieve strict purity — decide would still perform a side-effectful call (`clock.now()`) rather than operating on plain data. It also forces decide tests to create a `FixedClock` instead of simply passing `new Date('...')`, adding unnecessary ceremony to the simplest test tier.

### Alternative 3: `now` as a separate parameter to decide

Pass time as a plain value parameter: `bookDecide(command, state, now)`. The handler calls `clock.now()` and passes it directly.

Rejected because it couples time-awareness to the decide signature rather than the command. Placing `issuedAt` on the command keeps the decide signature minimal (`command, state`), makes the timestamp part of the command's identity, and aligns with DDD semantics: a command is a complete expression of intent, including when it was issued.

### Alternative 4: Caller-controlled timestamp on the command

Let the external caller (API layer or frontend) set the timestamp on the command DTO.

Rejected because the timestamp should reflect when the **system processed** the command, not when the caller sent it. Allowing the caller to set the timestamp opens the door to clock skew, replay attacks, and semantic confusion about what the timestamp means. The handler is the authority on "when did this command get issued" — it captures time via the trusted `Clock` port, not from untrusted external input.

## References

- Related: [ADR-0003](0003-use-fakes-over-mocks-for-testing.md) — Fakes over mocks
- Related: [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md) — Test at use case boundary
- Related: [ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md) — Domain function purity and dispatch
- Mark Seemann: "Functional architecture is Ports and Adapters" — https://blog.ploeh.dk/2016/03/18/functional-architecture-is-ports-and-adapters/
- Gary Bernhardt: "Boundaries" — https://www.destroyallsoftware.com/talks/boundaries
