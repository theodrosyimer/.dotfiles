# TDD Workflow & Implementation Patterns

## Overview

This document covers the **HOW** — concrete TDD workflow, corrected fake container pattern, acceptance test examples, query handlers with fixtures-as-stubs, and the frontend-first MVP pattern. For philosophy and reasoning, see [testing-philosophy.md](testing-philosophy.md).

**Testing framework: Vitest** — All examples use Vitest. Never use Jest.

## TDD Cycle: RED → GREEN → REFACTOR

### RED Phase: Failing Test First

- **NO PRODUCTION CODE** until you have a failing test
- Start with **acceptance criteria** as failing tests
- Use **minimal data requirements**
- Focus on **business behavior**, not implementation

### GREEN Phase: Minimal Implementation

- Write the **smallest amount of code** to make the test pass
- Resist the urge to add more functionality
- Schema-first validation integrated into handlers
- Types always derived from schemas

### REFACTOR Phase: Continuous Improvement

- Always assess refactoring opportunities after GREEN
- Only refactor if it adds value — don't change for change's sake
- Maintain external APIs during refactoring
- Commit refactoring separately from feature changes

## Fake Infrastructure Implementations

### Ultra-Light Repository Fake

```typescript
// packages/modules/src/{module}/infrastructure/repositories/listing.repository.fake.ts
import type { IListingRepository } from '@{module}/domain/ports/listing.repository.port'
import type { SpaceListingEntity } from '@{module}/domain/entities/listing.entity'

export class ListingRepositoryFake implements IListingRepository {
  // Test inspects: what was the handler asked to save?
  public savedListing: SpaceListingEntity | undefined

  // Test injects: what should findById return?
  public listingToReturn: SpaceListingEntity | undefined

  async save(listing: SpaceListingEntity): Promise<void> {
    this.savedListing = listing
  }

  async findById(id: string): Promise<SpaceListingEntity | null> {
    return this.listingToReturn ?? null
  }
}
```

### Predictable ID Provider

```typescript
// packages/shared/infrastructure/fakes/sequential-id.provider.ts
import type { IIdProvider } from '@{module}/domain/ports/id.provider.port'

export class SequentialIdProvider implements IIdProvider {
  private counter = 1

  generate(): string {
    return `fake-id-${this.counter++}`
  }

  reset(): void { this.counter = 1 }
}
```

### Fixed Date Provider

```typescript
// packages/shared/infrastructure/fakes/fixed-date.provider.ts
import type { IDateProvider } from '@{module}/domain/ports/date.provider.port'

export class FixedDateProvider implements IDateProvider {
  constructor(private fixedDate: Date = new Date('2025-01-15T10:00:00Z')) {}

  now(): Date { return this.fixedDate }

  setDate(date: Date): void { this.fixedDate = date }
}
```

### Ultra-Light File Storage Fake

```typescript
// packages/shared/infrastructure/fakes/file-storage.fake.ts
import type { IFileStorage } from '@{module}/domain/ports/file.storage.port'

export class FileStorageFake implements IFileStorage {
  public lastUploadPath: string | undefined
  public lastUploadUrl: string | undefined

  async upload(file: File, path: string): Promise<string> {
    this.lastUploadPath = path
    this.lastUploadUrl = `fake://storage/${path}`
    return this.lastUploadUrl
  }

  async delete(url: string): Promise<void> {
    // Ultra-light: no-op, test asserts on lastUploadPath if needed
  }
}
```

### Email Service Fake

```typescript
// packages/shared/infrastructure/fakes/email-service.fake.ts
import type { IEmailService, EmailMessage } from '@{module}/domain/ports/email.service.port'

export class EmailServiceFake implements IEmailService {
  readonly sentEmails: EmailMessage[] = []

  async send(message: EmailMessage): Promise<void> {
    this.sentEmails.push(message)
  }
}
```

## Fake Container Pattern

**Critical**: Domain services are instantiated as **real implementations**, not fakes. Only infrastructure ports are faked.

```typescript
// packages/modules/src/{module}/infrastructure/containers/fake.container.ts
import { ListingRepositoryFake } from '@{module}/infrastructure/repositories/listing.repository.fake'
import { FileStorageFake } from '@repo/shared/fakes/file-storage.fake'
import { SequentialIdProvider } from '@repo/shared/fakes/sequential-id.provider'
import { FixedDateProvider } from '@repo/shared/fakes/fixed-date.provider'
import { EmailServiceFake } from '@repo/shared/fakes/email-service.fake'

// Domain services — REAL implementations (pure logic, no I/O)
import { ListingValidationService } from '@{module}/domain/services/listing-validation.service'
import { BookingPricingService } from '@{module}/domain/services/booking-pricing.service'

// Handlers
import { CreateListingCommandHandler } from '@{module}/slices/create-listing/create-listing.handler'
import { PublishListingCommandHandler } from '@{module}/slices/publish-listing/publish-listing.handler'
import { CreateBookingCommandHandler } from '@{module}/slices/create-booking/create-booking.handler'

export function createFakeContainer(): Container {
  // Infrastructure fakes — these cross network/filesystem boundaries
  const listingRepository = new ListingRepositoryFake()
  const idProvider = new SequentialIdProvider()
  const dateProvider = new FixedDateProvider()
  const fileStorage = new FileStorageFake()
  const emailService = new EmailServiceFake()

  // Domain services — REAL instances (pure business logic, no I/O)
  const validationService = new ListingValidationService()
  const pricingService = new BookingPricingService()

  // Handlers — wired with faked infra + real domain services
  const createListingHandler = new CreateListingCommandHandler(
    listingRepository,    // fake (infra port)
    idProvider,           // fake (infra port)
    validationService     // REAL (domain service)
  )

  const publishListingHandler = new PublishListingCommandHandler(
    listingRepository,    // fake (infra port)
    validationService,    // REAL (domain service)
    emailService          // fake (infra port)
  )

  const createBookingHandler = new CreateBookingCommandHandler(
    listingRepository,    // fake (infra port)
    idProvider,           // fake (infra port)
    pricingService,       // REAL (domain service)
    emailService          // fake (infra port)
  )

  return {
    // Expose fakes for test assertions
    listingRepository,
    idProvider,
    dateProvider,
    fileStorage,
    emailService,

    // Expose domain services (real)
    validationService,
    pricingService,

    // Expose handlers
    createListingHandler,
    publishListingHandler,
    createBookingHandler,
  }
}
```

### Why This Matters

```typescript
// ❌ WRONG — faking a domain service
const validationService = new FakeValidationService() // Tests nothing!

// ✅ CORRECT — real domain service, faked infrastructure
const validationService = new ListingValidationService() // Real business rules
```

When the container uses real domain services, your acceptance tests validate the **actual business rule collaboration** between handler → domain service → entity. If a pricing rule changes in `BookingPricingService`, your acceptance tests catch it.

### Overridable Container (for FailingStub Injection)

Support overrides to inject error scenarios per test without rebuilding the entire container:

```typescript
type ContainerOverrides = {
  paymentGateway?: IPaymentGateway
  emailService?: IEmailService
}

export function createFakeContainer(overrides: ContainerOverrides = {}): Container {
  const emailService = overrides.emailService ?? new EmailServiceFake()
  const paymentGateway = overrides.paymentGateway ?? new PaymentGatewayFake()
  // ... rest of wiring uses overrides or defaults
}
```

Usage in tests:

```typescript
const container = createFakeContainer({
  paymentGateway: new PaymentGatewayFailingStub('cardDeclined')
})
```

## Acceptance Test Examples

### Feature Test with GIVEN-WHEN-THEN

```typescript
// slices/request-booking/request-booking.test.ts
import { describe, it, expect } from 'vitest'

describe('Feature: Request Booking', () => {
  describe('Scenario: Space is available', () => {
    it('should emit BookingRequested event', async () => {
      const eventStore = new BookingEventStoreFake()
      const clock = new FixedClockStub(new Date('2025-01-15T10:00:00Z'))
      const handler = new RequestBookingCommandHandler(eventStore, clock)

      const dto = createRequestBookingDTOFixture({
        spaceId: 'space-1',
      })
      await handler.execute(dto)

      const events = await eventStore.getEvents(dto.bookingId)
      expect(events).toHaveLength(1)
      expect(events[0]._tag).toBe('BookingRequested')
    })

    it('should send confirmation email', async () => {
      // ... same setup ...
      const dto = createRequestBookingDTOFixture()
      await handler.execute(dto)

      expect(emailService.sentEmails).toHaveLength(1)
      expect(emailService.sentEmails[0].to).toBe('customer@example.com')
    })
  })

  describe('Scenario: Space is not available', () => {
    it('should reject booking with domain error', async () => {
      const eventStore = new BookingEventStoreFake()
      const clock = new FixedClockStub()
      const handler = new RequestBookingCommandHandler(eventStore, clock)

      const dto = createRequestBookingDTOFixture()
      await expect(handler.execute(dto)).rejects.toThrow('Space not available for requested period')
    })
  })
})
```

### Handler Edge Case Tests

```typescript
// slices/create-listing/create-listing.handler.test.ts
import { describe, it, expect } from 'vitest'

describe('CreateListingCommandHandler', () => {
  it('should create a draft listing with generated ID', async () => {
    const repo = new ListingRepositoryFake()
    const idProvider = new SequentialIdProvider()
    const validationService = new ListingValidationService() // REAL
    const handler = new CreateListingCommandHandler(repo, idProvider, validationService)

    const dto = createCreateListingDTOFixture({ hourlyRate: 3.50 })
    await handler.execute(dto)

    // Assert on what was passed to save — no read-back
    expect(repo.savedListing).toBeDefined()
    expect(repo.savedListing!.props.id).toBe('fake-id-1')
    expect(repo.savedListing!.props.status).toBe('draft')
  })

  it('should reject dimensions below safety minimum', async () => {
    const repo = new ListingRepositoryFake()
    const handler = new CreateListingCommandHandler(
      repo, new SequentialIdProvider(), new ListingValidationService()
    )

    const dto = createCreateListingDTOFixture({ dimensions: { length: 1, width: 1 } })
    await expect(handler.execute(dto)).rejects.toThrow('Minimum dimensions not met')

    expect(repo.savedListing).toBeUndefined() // Nothing saved
  })
})
```

### Domain Entity Tests

```typescript
// domain/entities/listing.entity.test.ts
import { describe, it, expect } from 'vitest'
import { SpaceListingEntity } from './listing.entity'
import { createSpaceListingFixture } from '@{module}/slices/create-listing/fixtures/listing.fixture'

describe('SpaceListingEntity', () => {
  it('should not be valid without required fields', () => {
    const listing = createSpaceListingFixture({ title: '', pricing: { basePrice: 0, currency: 'USD' } })
    expect(listing.isValid()).toBe(false)
  })

  it('should enforce step progression rules', () => {
    const listing = createSpaceListingFixture({ spaceType: null })
    expect(listing.canProceedToStep(1)).toBe(false)

    listing.updateSpaceType({ id: 'storage', name: 'Storage' })
    expect(listing.canProceedToStep(1)).toBe(true)
  })

  it('should calculate refund based on cancellation timing', () => {
    const listing = createSpaceListingFixture()
    const refund = listing.calculateRefundAmount(100)
    expect(refund).toBeGreaterThanOrEqual(0)
  })
})
```

### Acceptance Test Checklist

- Tests at handler boundary (NOT through GUI)
- Fakes for infrastructure ports ONLY
- Domain services and entities are REAL
- Clear GIVEN-WHEN-THEN structure
- Tests WHAT (behavior), not HOW (implementation)
- Fresh fakes per test (direct instantiation, no shared container)
- All test data via `create` prefix + `Fixture` suffix functions/builders
- Vitest imports (not Jest)

## Query Handlers with Fixtures-as-Stubs

### The Pattern

For **query handlers** (read-only operations), we use **stubs** that return fixture data instead of fakes with internal logic. This enables:

1. **Frontend-first MVP**: Functional frontend with zero backend
2. **Agentic team contracts**: Fixtures as shared contracts between parallel agents

### Stub vs Fake Distinction (Meszaros)

- **Fake**: Ultra-light — records what was saved, returns what was injected. No internal logic. Used for command handlers.
- **Stub**: Returns canned answers from fixtures. No logic. Used for query handlers.

### Implementation

```typescript
// Fixture — defines the data shape (shared contract)
// slices/get-listing/fixtures/listing.fixture.ts
import type { SpaceListing } from '@{module}/domain/schemas/listing.schema'

export function createSpaceListingFixture(overrides?: Partial<SpaceListing>): SpaceListing {
  const listingFixtureDefault = {
    id: 'listing-001',
    spaceType: { id: 'parking', name: 'Parking Space' },
    title: 'Downtown Parking Spot',
    description: 'Secure parking near city center',
    dimensions: { length: 5, width: 2.5 },
    hourlyRate: 3.50,
    status: 'published',
    createdAt: new Date('2025-01-10'),
    updatedAt: new Date('2025-01-10')
  } satisfies SpaceListing

  return {
    ...listingFixtureDefault,
    id: `listing-${Date.now()}`,
    ...overrides
  }
}

export const listingListFixture = [
  createSpaceListingFixture(),
  createSpaceListingFixture({
    id: 'listing-2',
    spaceType: { id: 'storage', name: 'Storage Unit' },
    title: 'Climate Controlled Storage',
    description: 'Perfect for furniture',
    dimensions: { length: 3, width: 3 },
    hourlyRate: 5.00,
    status: 'draft',
    createdAt: new Date('2025-01-12'),
    updatedAt: new Date('2025-01-12')
  })
] satisfies SpaceListing[]
```

```typescript
// Stubbed query handler — returns fixture data, no logic
// slices/get-listing/get-listings.handler.ts
import type { IGetListingsQueryHandler } from '@{module}/domain/contracts/get-listings.handler.contract'
import type { SpaceListing } from '@{module}/domain/schemas/listing.schema'
import { listingListFixture } from './fixtures/listing.fixture'

export class GetListingsQueryHandler implements IGetListingsQueryHandler {
  async execute(): Promise<SpaceListing[]> {
    return listingListFixture // Canned answer — this is a STUB, not a fake
  }
}
```

```typescript
// Container wires stub for query, fake for command
export function createFakeContainer(): Container {
  // ... infrastructure fakes ...

  // Command handlers — use fakes (have state + logic)
  const createListingHandler = new CreateListingCommandHandler(listingRepository, idProvider)

  // Query handlers — use stubs (return fixture data)
  const getListingsHandler = new GetListingsQueryHandler()

  return { createListingHandler, getListingsHandler, /* ... */ }
}
```

### Frontend-First MVP Flow

```
Fixture (PRD data shape)
  → Query handler stub (returns fixture)
    → Container (wires stub)
      → Custom hook (useGetListings)
        → Component (renders data)

Result: Fully functional frontend with ZERO backend.
```

This means:
- **Frontend developer** builds UI against fixture data shape
- **Backend developer** implements the same data shape
- **Both work in parallel** — the fixture IS the contract
- **Swap stub for real** when backend is ready

### Agentic Team Usage

In LLM-assisted development, fixtures serve as **inter-agent contracts**:

```
Agent A (Frontend): Builds UI components consuming fixture data shape
Agent B (Backend): Implements repository/API returning same fixture data shape
Agent C (Tests): Writes acceptance tests using fixtures for expected outcomes

All agents share the same fixture file as their contract.
```

## Test Data Setup Patterns

### Rule: No Floating Literal Objects

Every test data object must come from a **fixture function**, a **builder**, or a **failing stub**. Never inline raw object literals in tests — they create noise, duplicate structure, and break across dozens of tests when schemas evolve.

```typescript
// ❌ NEVER — floating literal polluting the test
it('should create listing', async () => {
  const result = await handler.execute({
    spaceType: 'parking',
    dimensions: { length: 5, width: 2.5 },
    hourlyRate: 3.50,
    title: 'Test',
    description: 'Test desc',
    status: 'draft',
    // ... 10 more fields nobody cares about for THIS test
  })
})

// ✅ Fixture — only override what matters for the scenario
it('should create listing', async () => {
  const dto = createCreateListingDTOFixture({ hourlyRate: 3.50 })
  const result = await handler.execute(dto)
})
```

### Naming Rules

- Always `create` prefix + `Fixture` suffix: `createBookingFixture()`
- Builder keeps same convention: `createBookingFixture().confirmed().build()`
- No `a()`, `make()`, `build()`, `new()` — one convention, zero ambiguity

File naming uses kebab-case with `.fixture.ts` suffix:

```
slices/{feature}/fixtures/{entity}.fixture.ts
```

### Anti-Patterns

```typescript
// ❌ Floating literal — verbose, breaks when schema changes
const listing = {
  id: '123', spaceType: 'parking', dimensions: { length: 5, width: 2.5 },
  hourlyRate: 3.50, title: 'Test', description: 'Test', status: 'draft',
}

// ❌ Wrong prefix
const booking = aBooking().confirmed().build()
const listing = makeListing({ title: 'Test' })

// ❌ No suffix
const listing = createListing({ title: 'Test' })

// ✅ Fixture — expressive
const listing = createListingFixture({ hourlyRate: 3.50 })

// ✅ Builder — expressive
const booking = createBookingFixture().forListing(listing.id).confirmed().build()
```

### Fixture Functions (Simple Objects)

For objects with flat or predictable structure. Overrides let each test express only what matters.

```typescript
// slices/create-listing/fixtures/listing.fixture.ts
export function createSpaceListingFixture(
  overrides: Partial<CreateListingRequest> = {}
): CreateListingRequest {
  return CreateListingSchema.parse({
    spaceType: 'parking',
    dimensions: { length: 5, width: 2.5 },
    hourlyRate: 3.50,
    ...overrides,
  })
}
```

### Builder Pattern (Complex Objects with State Dependencies)

For objects where fields depend on each other or require multi-step construction. Use **only** when fixture overrides become awkward.

#### OOP Version (Preferred)

```typescript
// slices/create-booking/fixtures/booking.fixture.ts
export class BookingFixtureBuilder {
  private data: Partial<Booking> = {
    id: crypto.randomUUID(),
    status: 'pending',
    startTime: new Date('2025-01-15T10:00:00Z'),
    endTime: new Date('2025-01-15T12:00:00Z'),
  }

  forListing(id: string): this {
    this.data.listingId = id
    return this
  }

  withCustomer(id: string): this {
    this.data.customerId = id
    return this
  }

  confirmed(): this {
    this.data.status = 'confirmed'
    return this
  }

  spanning(start: Date, end: Date): this {
    this.data.startTime = start
    this.data.endTime = end
    return this
  }

  build(): Booking {
    return BookingSchema.parse(this.data)
  }
}

export function createBookingFixture(): BookingFixtureBuilder {
  return new BookingFixtureBuilder()
}
```

#### Functional Version (Alternative)

```typescript
export function createBookingFixture() {
  const defaults = {
    id: crypto.randomUUID(),
    listingId: 'listing-1',
    customerId: 'customer-1',
    startTime: new Date('2025-01-15T10:00:00Z'),
    endTime: new Date('2025-01-15T12:00:00Z'),
    status: 'pending' as const,
  }

  const builder = {
    forListing(id: string) { defaults.listingId = id; return builder },
    withCustomer(id: string) { defaults.customerId = id; return builder },
    confirmed() { defaults.status = 'confirmed'; return builder },
    spanning(start: Date, end: Date) {
      defaults.startTime = start
      defaults.endTime = end
      return builder
    },
    build() { return BookingSchema.parse(defaults) },
  }

  return builder
}
```

Usage — reads like a business scenario:

```typescript
const booking = createBookingFixture().forListing(listing.id).confirmed().build()
const longBooking = createBookingFixture().spanning(morning, evening).build()
```

### FailingStub (Saboteur Pattern — Infrastructure Error Scenarios)

For simulating typed infrastructure errors. The FailingStub throws `ApplicationException` on any method call — it's a Meszaros "saboteur" (a stub variant that injects faults). Integrates with the error architecture: failure map values are `ApplicationError` instances (using existing error subclasses), thrown via `ApplicationException.fromApplicationError()`.

```typescript
// infrastructure/event-store/payment-gateway-failing-stub.ts
import { ApplicationError } from '@/core/errors/application-error'
import { ApplicationException } from '@/core/errors/application-exception'
import { ResourceConflictError } from '@/core/errors/resource-conflict.error'
import type { IPaymentGateway } from '@{module}/domain/ports/payment-gateway.port'

// Infra-only failures — values are ApplicationError instances, not strings
const paymentGatewayFailures = {
  cardDeclined: new ApplicationError({
    code: 'card-declined',
    message: 'Card was declined',
    category: 'application-rule',
  }),
  networkTimeout: new ApplicationError({
    code: 'payment-network-timeout',
    message: 'Payment network timeout',
    category: 'infrastructure',
  }),
  providerConflict: new ResourceConflictError(
    'payment-provider-conflict',
    'Concurrent payment attempt detected',
    'payment',
    new Error('idempotency key conflict'),
  ),
} as const satisfies Record<string, ApplicationError>

export type PaymentGatewayFailure = keyof typeof paymentGatewayFailures

export class PaymentGatewayFailingStub implements IPaymentGateway {
  private readonly error: ApplicationError

  constructor(failure: PaymentGatewayFailure) {
    this.error = paymentGatewayFailures[failure]
  }

  async charge(): Promise<never> {
    throw ApplicationException.fromApplicationError(this.error)
  }

  async refund(): Promise<never> {
    throw ApplicationException.fromApplicationError(this.error)
  }
}
```

Usage in tests — expressive, typesafe, integrates with error architecture:

```typescript
it('should throw ApplicationException when payment is declined', async () => {
  const container = createFakeContainer({
    paymentGateway: new PaymentGatewayFailingStub('cardDeclined')
  })

  const dto = createRequestBookingDTOFixture()
  await expect(
    container.createBookingHandler.execute(dto)
  ).rejects.toSatisfy((error: ApplicationException) => {
    expect(error).toBeInstanceOf(ApplicationException)
    expect(error.metadata.category).toBe('application-rule')
    expect(error.metadata.code).toBe('card-declined')
    return true
  })
})

it('should throw infrastructure error on network timeout', async () => {
  const container = createFakeContainer({
    paymentGateway: new PaymentGatewayFailingStub('networkTimeout')
  })

  const dto = createRequestBookingDTOFixture()
  await expect(
    container.createBookingHandler.execute(dto)
  ).rejects.toSatisfy((error: ApplicationException) => {
    expect(error).toBeInstanceOf(ApplicationException)
    expect(error.metadata.category).toBe('infrastructure')
    return true
  })
})
```

**Why this pattern works:**

- **Typesafe**: Autocomplete on failure keys, impossible to invent nonexistent errors
- **Expressive**: `new PaymentGatewayFailingStub('cardDeclined')` reads as business language
- **Integrated**: Uses existing `ApplicationError` subclasses → `ApplicationException` → ProblemDetails. Proper HTTP status codes in API responses.
- **Co-located**: Failure map lives with the FailingStub in infrastructure/
- **Zero maintenance**: A const map + a class, not a framework

### Error Scenarios — Correct vs Incorrect

```typescript
// ❌ Generic "invalid" fixture — no type safety, no port context
export function createInvalidBooking(): Partial<Booking> {
  return { hourlyRate: -5 }
}

// ✅ Use a valid fixture with overrides that trigger domain rejection
const booking = createBookingFixture({ hourlyRate: -5 })
await expect(handler.execute(booking)).rejects.toThrow('Rate must be positive')

// ❌ Inline error setup — verbose, not expressive
const mockGateway = { charge: () => { throw new Error('Card declined') } }

// ❌ Raw Error in FailingStub — bypasses error architecture
throw new Error(this.message)  // Falls to unknown → 500

// ✅ Typed, expressive, integrated with error architecture
new PaymentGatewayFailingStub('cardDeclined')  // throws ApplicationException
```

### Summary: Test Data Patterns

| Need | Pattern | Example |
|------|---------|---------|
| Simple object creation | Fixture function | `createSpaceListingFixture({ hourlyRate: 5 })` |
| Complex object with state deps | Builder | `createBookingFixture().forListing(id).confirmed().build()` |
| Query read-only data | Stub with fixture | `GetListingsQueryHandler` |
| Infrastructure error scenario | FailingStub (saboteur) → `ApplicationException` | `new PaymentGatewayFailingStub('cardDeclined')` |
| Floating literal object | ❌ NEVER | — |

## Testing Commands

```bash
# TDD cycle — watch mode
pnpm test --watch

# Acceptance tests only
pnpm test --testPathPattern="acceptance"

# Component tests only (RNTL)
pnpm test --testPathPattern="component"

# Integration tests (slower, separate)
pnpm test:integration

# Full commit test suite (before push)
pnpm test && pnpm lint && pnpm check-types

# Coverage
pnpm test:coverage
```

## Performance & Reliability

- **Ultra-fast**: Ultra-light fake operations complete in microseconds
- **Deterministic**: Predictable IDs (SequentialIdProvider), fixed dates (FixedDateProvider)
- **Isolated**: Each test gets fresh container via `beforeEach`
- **No flakiness**: No network dependencies or timing issues
- **Debuggable**: Clear, traceable fake implementations
