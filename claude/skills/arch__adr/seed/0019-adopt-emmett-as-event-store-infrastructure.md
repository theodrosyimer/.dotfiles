# 0019. Adopt Emmett as Event Store Infrastructure

**Date**: 2026-04-02

**Status**: proposed

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: medium — Emmett's core is stable and used in production by others, but the library
is pre-1.0 with an undecided license (RFC mentions AGPLv3/SSPL). Integration with NestJS is
uncharted territory.

**Reevaluation triggers**: Emmett's license resolves as AGPLv3 or SSPL (incompatible with commercial
closed-source); Emmett's `EventStore` interface undergoes breaking changes in a minor release;
Emmett project is abandoned or development stalls for 6+ months; the dual async system (Emmett
Consumer + BullMQ) causes monitoring overhead that outweighs the benefit.

## Context

Our event-sourced modules (Booking, Listing, Payment, Discovery) use four pure domain functions —
`decide`, `evolve`, `project`, `react` — established in ADR-0009 and ADR-0012. The current
implementation uses a custom `EventStore<TEvent>` port with a Drizzle-based adapter handling
`append` and `loadEvents`. Command handling orchestration (load events → fold via evolve → decide →
append) is manual in each handler.

This manual orchestration lacks session scoping (aggregate + append must share a connection for
version safety), automatic optimistic concurrency resolution, retry-on-conflict with exponential
backoff, event schema versioning (upcast/downcast), and no-op detection. Implementing these
correctly is ~65-115 lines of subtle concurrent code where bugs hide for months under low contention.

Emmett (`@event-driven-io/emmett`) by Oskar Dudycz provides a `CommandHandler` function that handles
the full cycle — session scope, aggregateStream, version tracking, retry (3 retries, 100ms base,
1.5x factor), event versioning, and state forward-folding — plus a PostgreSQL event store with
partitioned tables, inline/async projections, and a consumer with checkpointing. The `EventStore`
interface in the core package is abstract and stable — it's the contract all store implementations
satisfy.

This decision builds on ADR-0009 (event source core subdomains), ADR-0012 (state-level dispatch in
domain functions), ADR-0015 (Clock captured in imperative shell), and ADR-0016 (ultra-light fakes).

## Decision

**We will adopt Emmett as the event store infrastructure layer, re-exporting its abstract
`EventStore` interface as our port, using `CommandHandler` for command handling orchestration, and
Emmett's async consumer for projections and reactor-to-BullMQ bridging.**

```
INTEGRATION ARCHITECTURE:

  Port:
    packages/modules/src/core/event-store/event-store.ts
      → re-exports EventStore from @event-driven-io/emmett
      → handlers depend on this, never on PostgresEventStore

  Write path:
    Executable.execute(dto)
      → Command.from(dto)                    // ACL boundary (Zod + Clock)
      → CommandHandler({ evolve, initialState })
        → aggregateStream → decide → appendToStream
      → return { newState, nextExpectedStreamVersion }
      → map to response DTO                  // write-side state to acting user

  Async event processing (Emmett consumer polls emt_messages):
    ├── projector: project → Pongo read model
    └── reactor: react → BullMQ.add()        // bridge to task queue

  Side effect execution:
    BullMQ worker → dispatch commands / TODO List pattern

  Query path:
    QueryHandler → Pongo collection / Drizzle query → DTO

FOUR PURE FUNCTIONS → EMMETT MAPPING:

  decide(command, state) → Result          ✅ Handler closure in CommandHandler
  evolve(state, event) → state             ✅ CommandHandler({ evolve })
  project(readModel, event) → readModel    ✅ pongoSingleStreamProjection({ evolve: project })
  react(event) → command[]                 ✅ consumer.reactor({ eachMessage })

EVENT DISCRIMINANT MIGRATION:

  Events: _tag → type   (Emmett's Event<T, D> requires type field)
  States: _tag → _tag   (internal, Emmett never sees)
  Commands: _tag → _tag  (internal, passed to decide only)
```

```
LIFECYCLE OWNERSHIP:

  NestJS owns all lifecycle — Emmett never manages process signals independently.

  EmmettCoreModule (global):
    ✅ provides EVENT_STORE (PostgresEventStore)
    ✅ onModuleDestroy → eventStore.close()

  EmmettConsumerModule:
    ✅ provides EMMETT_CONSUMER via eventStore.consumer()
    ✅ onModuleInit → consumer.start()
    ✅ beforeApplicationShutdown → consumer.stop()  // NOT close()

  Shutdown order:
    beforeApplicationShutdown → consumer.stop() → onModuleDestroy → eventStore.close()

  ⚠️  Emmett processors auto-register SIGTERM/SIGINT handlers (not opt-out).
      Upstream PR proposed to add disableGracefulShutdown option.
      Until merged: dual signal handlers fire — safe via idempotency guards
      (consumer.stop checks if (!isRunning) return).

ALLOWED:
  ✅ Import EventStore type from @repo/core/event-store (the re-export)
  ✅ Import CommandHandler from @event-driven-io/emmett (orchestration function)
  ✅ PostgresEventStore lifecycle methods in infrastructure modules only
  ✅ Emmett consumer + projector/reactor in NestJS infrastructure modules
  ✅ getInMemoryEventStore() in tests (satisfies same EventStore interface)

FORBIDDEN:
  ❌ Import PostgresEventStore in domain or application layer
  ❌ Import from @event-driven-io/emmett-postgresql in handlers
  ❌ Call consumer.close() from NestJS (kills shared pool)
  ❌ Inline projections (violates CQRS write/read separation)
  ❌ SSE or push for acting user (command response carries write-side state)
```

```
TWO ASYNC SYSTEMS — DIFFERENT RESPONSIBILITIES:

  Emmett Consumer:
    ✅ Event subscription from emt_messages (ES-native concern)
    ✅ Checkpointing global positions
    ✅ Projection execution (project → Pongo)
    ✅ Reactor: event → command translation (react → BullMQ.add)

  BullMQ:
    ✅ Command execution with retry/backoff/DLQ
    ✅ Independent failure strategies per consumer
    ✅ TODO List pattern for async workflows
    ✅ Monitoring via Bull Board

  Boundary: reactor is the bridge. Emmett reads events (its job),
  react translates events to commands (pure domain), BullMQ executes
  commands (its job). Each system stays in its competency.
```

## Consequences

### Positive

- Command handling gains session scoping, automatic optimistic concurrency, retry-on-conflict, event
  versioning, and no-op detection — all battle-tested in Emmett, not hand-rolled
- `CommandHandler` returns `{ newState, newEvents, nextExpectedStreamVersion }` — acting user gets
  write-side state immediately, eliminating the need for push infrastructure at MVP
- Emmett Consumer solves the outbox pattern natively — event store IS the outbox, consumer IS the
  publisher, checkpointing covers both projections and side effects
- `getInMemoryEventStore()` satisfies the same `EventStore` interface — tests need no NestJS, no PG
- Projection definitions reuse the `project` pure function directly
  (`pongoSingleStreamProjection({ evolve: bookingProject })`)
- Pongo provides MongoDB-like JSONB queries on PostgreSQL — no separate read database at MVP

### Negative

- Pre-1.0 dependency with undecided license — **must resolve before production deployment**
- Dual async system monitoring (Emmett Consumer + BullMQ) — two dashboards, two failure modes
- Event discriminant migration from `_tag` to `type` across all ES modules
- Emmett's processor-level SIGINT/SIGTERM registration conflicts with NestJS shutdown hooks (safe
  via idempotency, ugly until upstream opt-out is merged)
- Coupling to Emmett's `EventStore` interface shape — if it changes pre-1.0, the re-export and
  adapter need updating (handlers unaffected since they go through the re-export)

### Neutral

- Custom `EventStore<TEvent>` port (`append` + `getEvents`) replaced by Emmett's richer interface
  (`appendToStream`, `readStream`, `aggregateStream`) — different shape, same hexagonal role
- `Executable` interface unchanged — wraps `CommandHandler` internally, `ObservabilityDecorator`
  is unaware of Emmett
- BullMQ role narrows from "event consumer + executor" to "command executor only" — reactors bridge
  the gap

## Alternatives Considered

### Alternative 1: Explicit Port with Manual Command Handling Orchestration

Define a custom `EventStore<TEvent>` interface with `append` + `loadEvents`. Implement the
load → evolve → decide → append cycle manually in each handler. Build session scoping, retry, and
version tracking ourselves.

Rejected because the manual orchestration is ~65-115 lines of concurrent code where session + retry
interaction creates subtle bugs. The `EventStore` interface would need to mirror Emmett's shape
anyway (aggregateStream, version tracking) or lose correctness guarantees. The independence gained is
theoretical — we'd still depend on Emmett for storage, projections, and the consumer.

### Alternative 2: Skip Emmett Consumer, Use BullMQ for Everything

Use Emmett's EventStore and CommandHandler for the write path only. Skip Emmett's consumer entirely.
Use a BullMQ polling worker that reads from Emmett's `emt_messages` table for both projections and
side effects.

Rejected because BullMQ would need to understand event store internals — global positions,
checkpoint tables, stream filtering, Emmett's message format. That's the wrong abstraction boundary.
Emmett Consumer owns event subscription (its competency), BullMQ owns command execution (its
competency). The reactor bridges them cleanly.

### Alternative 3: Build Custom Event Store from Scratch

Implement event store on Drizzle directly — append table, version column, manual SQL for
aggregation. No external dependency.

Rejected because it reimplements Emmett's entire value proposition: partitioned tables, migration
management, projection infrastructure, consumer with checkpointing, connection pooling, and the
command handling cycle. The implementation effort is weeks, not days, and every piece needs testing
under concurrent load. Emmett has this battle-tested.

## References

- Project knowledge: [Emmett + NestJS Integration](emmett-nestjs-integration.md) — full integration
  artifact with both lifecycle solutions
- Project knowledge: [Event Modeling Pure Functions](event-modeling-pure-functions) — four pure
  function definitions
- Project knowledge: [Event Modeling Complete Guide](event-modeling-complete-guide-from-design-to-implementation.md) — Bobby Calderwood's domain functions architecture
- Project knowledge: [TODO List Pattern](todo-list-pattern-over-sagas.md) — BullMQ side effect
  execution pattern
- Project knowledge: [Event-Driven Architecture Reliability Patterns](Event_Driven_Architecture_Top_Patterns_for_Reliability.md) — outbox pattern and consumer independence
- Related: [ADR-0009](0009-event-source-core-subdomains-by-default.md) — ES for core subdomains
- Related: [ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md) — state-level dispatch in decide/evolve
- Related: [ADR-0015](0015-capture-time-in-imperative-shell-via-clock-port.md) — Clock captured at ACL, not passed to decide
- Related: [ADR-0016](0016-use-ultra-light-test-fakes-over-intelligent-inmemory.md) — testing with fakes
- Emmett repository: https://github.com/event-driven-io/emmett
- Emmett documentation: https://event-driven-io.github.io/emmett/
- Emmett license RFC: https://github.com/event-driven-io/emmett (pending resolution)
