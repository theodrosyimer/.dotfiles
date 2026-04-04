## Architecture Mapping from PRD

When you receive a PRD (from `development/plan-feature`), the **complexity level** determines the implementation approach. The PRD says WHAT to build; this section tells you HOW.

### CRUD → Narrow Ports + Transaction Script

**When PRD says `complexity: "CRUD"`**

Simple services, but still with narrow domain ports for testability. No entities, no domain services, no events — but the repository port stays because it provides the test seam for sociable unit tests.

- Narrow port (2-3 methods, abstract class in `domain/ports/`)
- Ultra-light fake implementing the port
- Standalone mapper in `infrastructure/mappers/` (pure `toDomain()`/`toPersistence()`)
- Zod schema for input validation at boundary
- No entities, no domain services, no events

```typescript
// domain/ports/user-settings.repository.ts — narrow port for test seam
export abstract class UserSettingsRepository {
  abstract findByUserId(userId: string): Promise<UserSettings | null>
  abstract save(settings: UserSettings): Promise<void>
}

// slices/update-settings/update-settings.handler.ts
export class UpdateSettingsCommandHandler {
  constructor(private repo: UserSettingsRepository) {}

  async execute(cmd: UpdateSettingsCommand): Promise<void> {
    const validated = UserSettingsUpdateSchema.parse(cmd)
    await this.repo.save(validated)
  }
}
```

### CQRS → Full Domain Architecture

**When PRD says `complexity: "CQRS"`**

Full domain layer with pure functions, handlers, event store ports, and events within a single bounded context. Based on the booking module pattern.

- Pure domain functions: `decide()`, `evolve()`, `project()`, `react()`
- Rich state types with discriminated unions (`_tag`)
- Handlers for workflow orchestration (CommandHandler for writes, QueryHandler for reads)
- Event store ports with ultra-light fakes for testing
- Comprehensive acceptance testing at handler boundary

```typescript
// Command handler — decide + append pattern (booking module)
export class RequestBookingCommandHandler implements Executable<RequestBookingDTO, void> {
  constructor(
    private readonly eventStore: EventStore<BookingEvent>,
    private readonly clock: Clock,
  ) {}

  async execute(input: RequestBookingDTO): Promise<void> {
    const command = RequestBookingCommand.from(input, this.clock.now())
    const events = await this.eventStore.getEvents(command.bookingId)
    const currentState = rebuildBookingState(events)
    const result = bookingDecide(command, currentState)

    if (!result.ok) {
      throw ApplicationException.fromDomainError(result.error)
    }

    await this.eventStore.append(command.bookingId, result.value)
  }
}

// Query handler — project from event stream
export class GetBookingDetailQueryHandler implements Executable<string, BookingDetailReadModel | null> {
  constructor(private readonly eventStore: EventStore<BookingEvent>) {}

  async execute(bookingId: string): Promise<BookingDetailReadModel | null> {
    const events = await this.eventStore.getEvents(bookingId)
    const readModel = events.reduce(bookingProject, INITIAL_BOOKING_READ_MODEL)
    if (readModel._tag === 'NoBooking') return null
    return { bookingId: readModel.bookingId, guestId: readModel.guestId, /* ... */ }
  }
}
```

### CROSS_CONTEXT → CQRS + Cross-Context Communication

**When PRD says `complexity: "CROSS_CONTEXT"`**

Everything in CQRS, plus: read the PRD's `crossContextDependencies` and implement Gateway/ACL/event patterns.

**Step 1: Read PRD dependencies**

The PRD provides dependency directions only:
```json
{
  "crossContextDependencies": {
    "contexts": [
      { "name": "booking", "entities": ["Booking"], "responsibility": "Manages reservations" },
      { "name": "billing", "entities": ["Invoice"], "responsibility": "Handles payments" }
    ],
    "dependencies": [
      { "from": "billing", "to": "booking", "reason": "Billing needs booking data for invoicing" }
    ]
  }
}
```

**Step 2: Map dependencies to patterns**

| Need | Pattern | Provider Creates | Consumer Creates |
|------|---------|-----------------|------------------|
| Synchronous data query | Gateway + ACL | Gateway in `contracts/` + DTOs | Domain port + ACL in `infrastructure/adapters/` |
| React to something that happened | Domain Events + Handler | Event class + publish in handler | Event handler + ACL |
| Both | Combined | Gateway + Events | ACL + Handler |

**Step 3: Implementation order**

1. Implement depended-upon context first (provider) — including its Gateway
2. Implement dependent context second (consumer) — including its ACL
3. Wire containers — inject Gateways into consumers
4. Integration stories last — test cross-context workflows

**See `references/cross-context-patterns.md` for:** complete Gateway implementation, ACL patterns, event-driven communication, testing strategies, container wiring, dependency rules.
