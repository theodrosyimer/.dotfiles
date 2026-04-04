# 0012. Use State-Level Switch/Case for Domain Function FSMs

**Date**: 2026-03-08

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — pattern validated in bookingDecide, bookingEvolve, spaceDecide, spaceEvolve with full TypeScript narrowing

**Reevaluation triggers**: State machines grow to include parallel states, delayed transitions, or hierarchical states (XState territory); a third bounded context with identical FSM shape makes the duplication a maintenance burden; TypeScript adds native pattern matching that makes the nested switch less ergonomic by comparison.

## Context

Our event modeling architecture has four domain functions (two per bounded context) that are finite
state machines: `bookingDecide`, `bookingEvolve`, `spaceDecide`, `spaceEvolve`. Each dispatches on
two discriminants — state and input (command or event).

The original implementation dispatched on the input first (`switch (command._tag)`) with state
guards inside each branch (`if (currentState._tag !== 'RequestedBooking')`). This scattered state
transition rules across command branches, making it hard to answer "what can happen from this
state?" without reading the entire function.

We explored three approaches to restructuring these functions:

- **Approach A — Transition table**: declare all transitions as data
  (`Record<CommandTag, StateTag[]>`). Exhaustive via `satisfies`, but loses TypeScript narrowing —
  requires `as any` casts to access state fields like `spaceId`, because the guard and the outcome
  logic are separated.

- **Approach B — Named guard functions**: one function per command (`canCancelBooking(state)`).
  Expressive for complex multi-field guards, but not exhaustive by default — nothing forces you to
  write a guard for a new command.

- **Approach C — State-level switch/case**: outer switch on `state._tag`, inner switch on
  `command._tag` (or `event._tag` for Evolve). Each state block declares its accepted inputs.

We also evaluated extracting a generic `createDecider`/`createEvolver` abstraction and using XState
v5.

## Decision

**We will use state-level nested switch/case (Approach C) for all Decide and Evolve functions.**

The outer switch dispatches on `state._tag`. The inner switch dispatches on the input
(`command._tag` for Decide, `event._tag` for Evolve). Each state block declares its valid
transitions. Terminal states reject all inputs explicitly.

```
STRUCTURE:

  switch (currentState._tag) {

    case 'RequestedBooking': {        ← state declares its transitions
      switch (command._tag) {
        case 'ConfirmBooking': ...    ← TypeScript narrows BOTH state and command
        case 'CancelBooking':  ...
        default: ...                  ← rejects everything else
      }
    }

    case 'CanceledBooking':           ← terminal, explicit dead end
    case 'CompletedBooking':
      return ... (reject for Decide, ignore for Evolve)
  }
```

```
SEMANTIC DIFFERENCE BETWEEN DECIDE AND EVOLVE:

  Decide: unhandled = Result.failWith("Cannot ...")    ← strict, rejects invalid commands
  Evolve: unhandled = return currentState              ← forgiving, ignores unexpected events
```

**We will NOT abstract this into a generic `createDecider`/`createEvolver` factory.**

**We will NOT use XState for this purpose at this time.**

## Consequences

### Positive

- **TypeScript narrows both discriminants natively** — `currentState.spaceId` is accessible inside
  `case 'RequestedBooking'` without type assertions or `as any` casts
- **Exhaustiveness is enforced** — adding a new state to the ADT union without handling it in the
  switch produces a compile error (when the return type is declared)
- **Reads like the state diagram** — scanning a state block immediately shows all valid transitions
  from that state. The code IS the state machine documentation
- **Zero dependencies** — no library, no generic framework, no abstraction layer between the
  developer and the logic
- **Debugger-friendly** — step through the switch, see exactly which branch executes. No indirection
  through lookup tables or handler maps

### Negative

- **Repeated transition handlers** — `CancelBooking` appears in both `RequestedBooking` and
  `ConfirmedBooking` blocks. In the transition table approach (A), it would be one row:
  `CancelBooking: ['RequestedBooking', 'ConfirmedBooking']`
- **More lines of code** — the nested switch is more verbose than a declarative table. Four
  functions × ~60 lines each versus a table-driven approach at ~20 lines each
- **No automatic visualization** — XState would give a visual state diagram at stately.ai/viz for
  free. With switch/case, visualization requires a separate tool or manual diagram

### Neutral

- The pattern repeats across bounded contexts (booking + listing) but this is accidental
  duplication, not essential — each FSM has different states, different transitions, and different
  semantics
- If a third bounded context is added and the repetition becomes a maintenance burden, the
  abstraction decision can be revisited

## Alternatives Considered

### Alternative 1: Transition Table (Approach A)

Declare transitions as `Record<CommandTag, StateTag[]>` with a `guardFromTable` function. The entire
state machine fits in one glance. Exhaustive via `satisfies Record<...>`.

**Rejected because**: The guard and the outcome logic are separated into two functions. The outcome
function (`buildEvents`) receives the full `BookingState` union without narrowing — TypeScript
doesn't know the guard already ran. Requires `(state as { spaceId: string }).spaceId` casts or an
`ActiveBookingState` wrapper type. Loses the primary benefit we sought: type-safe access to state
fields.

### Alternative 2: Named Guard Functions (Approach B)

One guard function per command: `canCancelBooking(state) → boolean`. Guards are independently
testable and can express complex multi-field conditions.

**Rejected because**: Not exhaustive by default — adding a new command doesn't force you to write a
guard. Requires a manual `GUARD_MAP: Record<CommandTag, GuardFn>` to bridge guards to the dispatch.
More code than the switch/case for simple state-tag-only guards, which is all we currently need.

### Alternative 3: Generic `createDecider`/`createEvolver` Abstraction

Extract the pattern into a factory function that accepts a `TransitionMap<TState, TInput, TOutput>`
and returns the dispatch function.

**Rejected because**: The generic types require `as any` casts internally to satisfy TypeScript's
narrowing. The `TransitionMap` type uses optional properties (`?`) for transitions, which means
exhaustiveness is lost — omitting a state silently produces no error. The four functions look
structurally similar but have different semantics (Decide rejects, Evolve ignores; Decide returns
Result, Evolve returns state). Abstracting them hides these semantic differences.

### Alternative 4: XState v5

Define the state machine using `createMachine`, extract Decide/Evolve as wrappers around
`machine.transition()`. Gains: visual inspector, typegen for exhaustiveness, named guards.

**Rejected for now because**: XState merges Decide + Evolve into one transition function, which
conflicts with event modeling's explicit separation of write-side (Decide) and read-side (Evolve).
The library adds ~15KB and a different mental model (context, assign, invoke) on top of our existing
pure function architecture. The current switch/case already provides exhaustiveness via TypeScript
and type narrowing natively. If the state machines grow complex (parallel states, delayed
transitions, hierarchical states), this decision should be revisited.

## References

- [Jérémie Chassaing — Functional Event Sourcing Decider](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider)
- [Kuba Zalas — Functional Event Sourcing](https://zalas.pl/functional-event-sourcing/) — "I'm in
  favour of explicit domain errors rather than using exceptions"
- [XState v5 documentation](https://stately.ai/docs/machines)
- [ts-pattern](https://github.com/gvergnaud/ts-pattern) — evaluated for `.exhaustive()`, but
  TypeScript's native switch already enforces exhaustiveness on discriminated unions
