# Cross-Context Implementation Patterns - Detailed Reference

## Overview

When a PRD specifies `CROSS_CONTEXT` complexity with inter-context dependencies, this reference
guides the **implementation decisions**: which communication pattern to use, where each piece lives
in the module structure, and how to test it.

The PRD only states dependency direction (e.g., "Billing depends on Booking"). This reference tells
you HOW to implement that dependency.

## The Two Complementary Patterns

Cross-context communication always involves two sides:

```
PROVIDER MODULE                 CONSUMER MODULE
┌─────────────────┐            ┌──────────────────┐
│                 │            │                  │
│  Domain Model   │            │  Domain Model    │
│                 │            │                  │
│  ┌───────────┐  │            │  ┌────────────┐  │
│  │ Gateway   │  │───────────▶│  │    ACL     │  │
│  │ (PUBLIC)  │  │            │  │ (Adapter)  │  │
│  └───────────┘  │            │  └────────────┘  │
│  contracts/     │            │  infrastructure/  │
│                 │            │  adapters/        │
└─────────────────┘            └──────────────────┘
     PROVIDER                     CONSUMER
```

| Aspect         | Gateway (Provider)                       | ACL/Adapter (Consumer)                             |
| -------------- | ---------------------------------------- | -------------------------------------------------- |
| **Location**   | `{module}/contracts/{module}.gateway.ts` | `{module}/infrastructure/adapters/{source}.acl.ts` |
| **Purpose**    | Expose stable public API                 | Translate external model to internal               |
| **Returns**    | DTOs (contract objects)                  | Domain objects (internal model)                    |
| **Interface**  | `I{Module}Gateway`                       | Domain port (e.g., `ISpaceAvailabilityChecker`)    |
| **Naming**     | `SpaceListingGateway`                    | `SpaceListingAdapter`                              |
| **Versioning** | Must maintain backward compatibility     | Can migrate independently                          |

## Decision Framework: Reading PRD Dependencies

When the PRD says `"Context B depends on Context A"`:

1. **Context A (depended-upon)** → Implement first, expose a **Gateway** in `contracts/`
2. **Context B (dependent)** → Implement second, consume via **ACL** in `infrastructure/adapters/`

### Choosing the Communication Pattern

```
PRD says: "Context B depends on Context A"
                    ↓
┌─────────────────────────────────────┐
│ Does Context B need SYNCHRONOUS     │
│ data from Context A?                │
│ (e.g., "check availability",       │
│  "get pricing", "verify identity") │
└─────────────────────────────────────┘
          ↓ YES                    ↓ NO
┌─────────────────────┐  ┌────────────────────────┐
│ Gateway + ACL        │  │ Does Context B need to  │
│ (request/response)   │  │ REACT to something that │
│                      │  │ happened in Context A?  │
│ Context A: Gateway   │  │ (e.g., "when booking    │
│ Context B: ACL       │  │  confirmed, send email")│
└─────────────────────┘  └────────────────────────┘
                                   ↓ YES
                         ┌────────────────────────┐
                         │ Domain Events + Handler │
                         │                         │
                         │ Context A: publishes    │
                         │   event via EventBus    │
                         │ Context B: subscribes   │
                         │   handler + ACL         │
                         └────────────────────────┘
```

**Both patterns can coexist.** A consumer module might use Gateway+ACL for synchronous queries AND
event handlers for reactive workflows.

## Pattern 1: Gateway + ACL (Synchronous)

### Provider Side: Gateway

The Gateway is the module's **public API** — the only thing other modules may import.

```typescript
// packages/modules/src/listing/contracts/listing.gateway.ts

export class SpaceListingGateway implements ISpaceListingGateway {
  constructor(private readonly listingRepository: IListingRepository) {}

  // PUBLIC CONTRACT — other modules depend on this shape
  async getSpaceAvailability(spaceId: string): Promise<SpaceAvailabilityDTO> {
    const listing = await this.listingRepository.findById(spaceId)

    if (!listing) {
      throw new SpaceNotFoundException(spaceId)
    }

    // Return DTO — NEVER expose internal domain entities
    return {
      spaceId: listing.props.id,
      isActive: listing.props.status === 'active',
      calendar: {
        bookedSlots: listing.props.calendar.bookedSlots.map((slot) => ({
          start: slot.start.toISOString(),
          end: slot.end.toISOString(),
        })),
      },
    }
  }
}

// packages/modules/src/listing/contracts/dtos/space-availability.dto.ts
export type SpaceAvailabilityDTO = {
  spaceId: string
  isActive: boolean
  calendar: {
    bookedSlots: TimeSlotDTO[]
  }
}

export type TimeSlotDTO = {
  start: string // ISO 8601
  end: string // ISO 8601
}
```

**Gateway rules:**

- ✅ Returns DTOs, never internal entities
- ✅ Handles backward compatibility (versioning if needed)
- ✅ Lives in `{module}/contracts/`
- ❌ Never exposes repository interfaces
- ❌ Never leaks domain events directly

### Consumer Side: ACL (Anti-Corruption Layer)

The ACL translates the provider's DTOs into the consumer's domain language.

```typescript
// packages/modules/src/booking/domain/ports/space-availability-checker.port.ts

// Domain port — uses BOOKING's ubiquitous language
export interface ISpaceAvailabilityChecker {
  isAvailable(spaceId: string, period: BookingPeriod): Promise<boolean>
}
```

```typescript
// packages/modules/src/booking/infrastructure/adapters/listing.acl.ts

import type { ISpaceListingGateway } from '@listing/contracts/listing.gateway'
import type { ISpaceAvailabilityChecker } from '@booking/domain/ports/space-availability-checker.port'
import { BookingPeriod } from '@booking/domain/value-objects/booking-period.value-object'

// ACL implements a DOMAIN port, not the Gateway interface
export class SpaceListingACL implements ISpaceAvailabilityChecker {
  constructor(private readonly spaceListingGateway: ISpaceListingGateway) {}

  async isAvailable(spaceId: string, period: BookingPeriod): Promise<boolean> {
    // 1. Call external Gateway
    const dto = await this.spaceListingGateway.getSpaceAvailability(spaceId)

    // 2. Translate DTO → domain model (Booking's language)
    const bookedPeriods = dto.calendar.bookedSlots.map((slot) =>
      BookingPeriod.fromDates(new Date(slot.start), new Date(slot.end)),
    )

    // 3. Apply domain logic in Booking's terms
    return !bookedPeriods.some((booked) => booked.overlapsWith(period)) && dto.isActive
  }
}
```

**ACL rules:**

- ✅ Implements a domain port (not the Gateway interface)
- ✅ Translates foreign DTOs into local domain objects
- ✅ Uses local ubiquitous language for method names
- ✅ Lives in `{module}/infrastructure/adapters/`
- ❌ Never lets DTOs leak into domain layer
- ❌ Never used directly by handlers (use the domain port)

### Handler Consuming the ACL

The handler depends on the **domain port**, never on the ACL or Gateway directly:

```typescript
// packages/modules/src/booking/slices/create-booking/create-booking.handler.ts

export class CreateBookingCommandHandler implements Executable<
  CreateBookingRequest,
  BookingEntity
> {
  constructor(
    private readonly bookingRepository: IBookingRepository,
    private readonly availabilityChecker: ISpaceAvailabilityChecker, // Domain port
    private readonly idProvider: IIdProvider,
  ) {}

  async execute(request: CreateBookingRequest): Promise<BookingEntity> {
    const period = BookingPeriod.fromDates(request.startTime, request.endTime)

    // Handler doesn't know about Space Listing internals
    const isAvailable = await this.availabilityChecker.isAvailable(request.spaceId, period)

    if (!isAvailable) {
      throw new SpaceNotAvailableException(request.spaceId, period)
    }

    const booking = new BookingEntity({
      id: this.idProvider.generate(),
      spaceId: request.spaceId,
      // ...
    })

    await this.bookingRepository.save(booking)
    return booking
  }
}
```

## Pattern 2: Domain Events + Handler (Asynchronous)

When Context B needs to **react** to something that happened in Context A.

### Provider Side: Publishes Event

```typescript
// packages/modules/src/booking/domain/events/booking-confirmed.event.ts
export class BookingConfirmedEvent {
  constructor(
    public readonly bookingId: string,
    public readonly spaceId: string,
    public readonly customerId: string,
    public readonly period: { start: Date; end: Date },
    public readonly totalPrice: number,
  ) {}
}
```

```typescript
// In the handler that confirms the booking:
await this.eventBus.publish(
  new BookingConfirmedEvent(
    booking.props.id,
    booking.props.spaceId,
    booking.props.customerId,
    { start: booking.props.startTime, end: booking.props.endTime },
    booking.props.totalPrice,
  ),
)
```

### Consumer Side: Event Handler + ACL

```typescript
// packages/modules/src/billing/slices/handle-booking-confirmed/handle-booking-confirmed.handler.ts

import type { IBookingACL } from '@billing/infrastructure/booking.acl'

export class HandleBookingConfirmedCommandHandler {
  constructor(
    private readonly bookingACL: IBookingACL,
    private readonly invoiceRepository: IInvoiceRepository,
    private readonly idProvider: IIdProvider,
  ) {}

  async handle(event: BookingConfirmedEvent): Promise<void> {
    // 1. Translate event data → local domain language via ACL
    const billableItem = await this.bookingACL.toBillableItem(event)

    // 2. Perform local domain action
    const invoice = new InvoiceEntity({
      id: this.idProvider.generate(),
      customerId: billableItem.customerId,
      lineItems: [billableItem],
      status: 'pending',
      createdAt: new Date(),
      updatedAt: new Date(),
    })

    await this.invoiceRepository.save(invoice)
  }
}
```

```typescript
// packages/modules/src/billing/infrastructure/adapters/booking.acl.ts

export class BookingACL implements IBookingACL {
  // Translate foreign event data to Billing's language
  async toBillableItem(event: BookingConfirmedEvent): Promise<BillableItem> {
    return {
      description: `Space booking ${event.bookingId}`,
      amount: event.totalPrice,
      customerId: event.customerId,
      serviceDate: event.period.start,
    }
  }
}
```

## Pattern 3: Combined (Both Patterns)

Some modules need both synchronous queries AND reactive handlers:

```
Billing Module needs:
  1. Gateway+ACL → to query Booking details (synchronous)
  2. Event Handler → to react when bookings are confirmed (async)

Both use the same ACL adapter for translation consistency.
```

## Testing Cross-Context Patterns

### Testing the Gateway (Provider)

```typescript
describe('SpaceListingGateway', () => {
  it('should return DTO without leaking domain internals', async () => {
    const repository = new ListingRepositoryFake()
    const gateway = new SpaceListingGateway(repository)

    // Setup: save a listing
    const listing = new SpaceListingEntity({
      /* ... */
    })
    await repository.save(listing)

    // Act
    const dto = await gateway.getSpaceAvailability(listing.props.id)

    // Assert: DTO shape, not entity shape
    expect(dto.spaceId).toBe(listing.props.id)
    expect(dto.calendar.bookedSlots).toBeInstanceOf(Array)
    // DTO uses ISO strings, not Date objects
    expect(typeof dto.calendar.bookedSlots[0]?.start).toBe('string')
  })
})
```

### Testing the ACL (Consumer)

```typescript
describe('SpaceListingACL', () => {
  it('should translate DTO to domain model', async () => {
    // Stub the Gateway (returns known DTO)
    const gatewayStub: ISpaceListingGateway = {
      getSpaceAvailability: async () => ({
        spaceId: 'space-1',
        isActive: true,
        calendar: {
          bookedSlots: [{ start: '2024-01-01T10:00:00Z', end: '2024-01-01T12:00:00Z' }],
        },
      }),
    }

    const acl = new SpaceListingACL(gatewayStub)
    const period = BookingPeriod.fromDates(
      new Date('2024-01-01T14:00:00Z'),
      new Date('2024-01-01T16:00:00Z'),
    )

    const result = await acl.isAvailable('space-1', period)
    expect(result).toBe(true) // No overlap
  })
})
```

### Testing Handlers with Faked Domain Port

In acceptance tests, fake the **domain port** — the handler never knows about Gateways or ACLs:

```typescript
describe('CreateBookingCommandHandler', () => {
  it('should create booking when space is available', async () => {
    // Fake the domain port (not the Gateway)
    const availabilityChecker: ISpaceAvailabilityChecker = {
      isAvailable: async () => true,
    }

    const handler = new CreateBookingCommandHandler(
      new BookingRepositoryFake(),
      availabilityChecker, // Faked at domain boundary
      new SequentialIdProvider(),
    )

    const dto = createCreateBookingDTOFixture()
    const booking = await handler.execute(dto)
    expect(booking.props.status).toBe('confirmed')
  })
})
```

## Dependency Rules

```
INTER-MODULE COMMUNICATION:
  ✅ Module slices/ → other module contracts/       (via Gateway DTOs)
  ❌ Module slices/ → other module domain/          (breaks encapsulation)
  ❌ Module slices/ → other module slices/          (creates coupling)
  ❌ Module slices/ → other module infrastructure/  (leaks implementation)

WITHIN CONSUMER MODULE:
  ✅ Handler → domain port                             (ISpaceAvailabilityChecker)
  ✅ ACL → Gateway interface                          (ISpaceListingGateway)
  ✅ ACL implements domain port                       (SpaceListingACL implements ISpaceAvailabilityChecker)
  ❌ Handler → Gateway directly                       (bypasses ACL translation)
  ❌ Handler → ACL class directly                     (depend on port, not implementation)
  ❌ Domain layer → Gateway                           (domain must not know about external modules)
```

## Container Wiring for Cross-Context

```typescript
// packages/modules/src/booking/infrastructure/containers/booking.container.ts

export function createBookingContainer(
  spaceListingGateway: ISpaceListingGateway, // Injected from outside
): BookingContainer {
  // ACL wraps the external gateway
  const spaceListingACL = new SpaceListingACL(spaceListingGateway)

  // Handlers depend on domain ports, ACL provides the implementation
  const createBookingCommandHandler = new CreateBookingCommandHandler(
    new BookingRepositoryFake(),
    spaceListingACL, // Satisfies ISpaceAvailabilityChecker
    new SequentialIdProvider(),
  )

  return {
    createBookingCommandHandler,
    // ...
  }
}
```

## Implementation Checklist

When implementing a CROSS_CONTEXT feature from a PRD:

1. **Read PRD dependencies** — identify provider and consumer modules
2. **Implement provider first** — build the depended-upon context:
   - Domain layer (entities, schemas, handlers)
   - Gateway in `contracts/` with DTOs
3. **Implement consumer second** — build the dependent context:
   - Domain layer with domain port for the external dependency
   - ACL in `infrastructure/adapters/` implementing the domain port
   - Handlers depending on the domain port
4. **Wire containers** — inject Gateways into consumers via ACL
5. **Test in isolation** — fake domain ports in acceptance tests, test Gateway and ACL separately

## Summary

```
PROVIDER (depended-upon):
├─ contracts/
│  ├─ {module}.gateway.ts        # Public API — returns DTOs
│  └─ dtos/                      # Contract objects
└─ Responsibility: stable interface, backward compatibility

CONSUMER (dependent):
├─ domain/ports/
│  └─ {concept}.port.ts          # Domain interface in local language
├─ infrastructure/adapters/
│  └─ {source-context}.acl.ts    # Translates DTOs → domain objects
└─ Responsibility: protect domain model, translate foreign concepts

EVENT-DRIVEN:
├─ Provider publishes domain events via EventBus
├─ Consumer subscribes with event handler
└─ Handler uses ACL to translate event data → local domain
```

**The clean boundary**: plan-feature's PRD says "Billing depends on Booking" (a planning fact).
Implement-feature reads that and decides: "Booking exposes a Gateway, Billing consumes it via an
ACL" (an architecture decision). The plan never mentions Gateway or ACL.
