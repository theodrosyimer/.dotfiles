# Bounded Context Contracts -- Where Zod Schemas Live

This reference helps dev__type-driven-zod-boundaries by defining how bounded context boundaries determine Zod schema placement.

## Core Principle

Zod schemas live at boundaries -- the seams between bounded contexts, between the application and the outside world. Domain internals use plain TypeScript types with discriminated unions.

## Bounded Context Boundaries Are Language Boundaries

Bounded contexts are drawn where ubiquitous language changes. The same term ("Booking") means different things in different contexts:

- **Booking Context**: A reserved time slot for a space
- **Listing Context**: A slot in the calendar

Each context has its own domain model with its own types. Communication between contexts crosses a boundary that needs validation.

## Where Boundaries Exist (Zod Schema Locations)

### 1. Gateway DTOs (Inter-Module Contracts)
The provider module's `contracts/` directory exposes DTOs validated with Zod:
```
contracts/
  gateway.ts          # Interface with DTO return types
  dtos/
    space-availability.schema.ts   # Zod schema
    time-slot.schema.ts            # Zod schema
```
These are the published API of the bounded context. Consumers must validate what they receive.

### 2. API Input (External World -> Application)
HTTP request bodies, query params, path params:
```
slices/{feature}/
  {feature}.command.ts    # Zod schema for command input
  {feature}.query.ts      # Zod schema for query input
```

### 3. External Data (DB, Third-Party, Environment)
Data entering from infrastructure:
```
infrastructure/
  mappers/
    toPersistence.ts      # Domain -> DB (Zod optional, Drizzle handles)
    toDomain.ts           # DB -> Domain (Zod validates incoming shape)
  adapters/
    payment-provider.adapter.ts  # Third-party response Zod validation
```

### 4. Environment Configuration
```
src/config/
  env.schema.ts           # Zod schema for process.env
```

## Where Zod Does NOT Belong

### Domain Internals
- Entity types: plain `type` with `_tag` discriminated unions
- Value objects: plain `type` aliases
- Domain events: plain `type` with `_tag`
- Domain commands: plain `type` with `_tag`

```typescript
// CORRECT: plain type in domain
type BookingState =
  | { _tag: 'NoBooking' }
  | { _tag: 'Requested'; guestId: GuestId; spaceId: SpaceId }
  | { _tag: 'Confirmed'; confirmationId: string }
```

### Intra-Module Communication
- Domain service parameters: typed by domain types, no Zod
- Entity method arguments: typed by domain types, no Zod
- Handler internal orchestration: already validated at entry point

## The Pattern: z.infer, Never Duplicate

When a Zod schema exists at a boundary, always derive the type from it:

```typescript
const CreateBookingSchema = z.object({
  spaceId: SpaceIdSchema,
  guestId: GuestIdSchema,
  startDate: z.string().datetime(),
  endDate: z.string().datetime(),
})

type CreateBookingCommand = z.infer<typeof CreateBookingSchema>
// NEVER: type CreateBookingCommand = { spaceId: string; ... } alongside schema
```

## Context Relationship and Validation Responsibility

| Relationship | Who Validates? | Where? |
|-------------|---------------|--------|
| Provider (Gateway) | Provider validates outgoing DTOs | contracts/ Zod schemas |
| Consumer (ACL) | Consumer validates incoming DTOs | infrastructure/adapters/ |
| API Input | Application validates request | slices/{feature}/ Zod schemas |
| DB Read | Mapper validates DB row shape | infrastructure/mappers/ |
| Third-Party | Adapter validates response | infrastructure/adapters/ |

## Boundary Validation = Structural Only

Zod schemas at boundaries validate **structure** (shape, format, types). Business rules are enforced by entities and domain services, NOT by Zod schemas.

```typescript
// Boundary: structural validation
const schema = z.object({
  email: z.string().email(),        // Format check
  startDate: z.string().datetime(), // Format check
  spaceId: SpaceIdSchema,           // Type/format check
})

// Domain: business rule validation
const booking = BookingEntity.create(validatedInput)
// Entity enforces: "start date must be in the future"
// Entity enforces: "booking duration minimum 1 hour"
```
