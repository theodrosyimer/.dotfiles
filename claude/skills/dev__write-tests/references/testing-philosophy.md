# Testing Philosophy & Architecture

## Overview

Our testing strategy validates **business behavior through handlers at the application service boundary** (hexagonal architecture), not through the GUI. We use **sociable unit tests** with real domain objects and faked infrastructure, producing ultra-fast, reliable, refactoring-resilient tests.

This document covers the **WHY** — philosophy, principles, and architectural reasoning. For implementation examples and HOW, see [tdd-workflow.md](tdd-workflow.md).

## Sociable vs Solitary Testing

Our acceptance tests follow the **classicist (Detroit/Chicago) school** of TDD, producing **sociable unit tests** at the handler boundary.

### Sociable Unit Tests (Our Approach)

A sociable unit test exercises the **real collaboration between objects** — the handler calls real domain services, which operate on real entities. Only infrastructure ports (repositories, external APIs) are replaced with fakes.

```
Handler (real)
  ├── Domain Service (real) ← Pure business logic, no I/O
  │     └── Entity (real)   ← Business rules, state transitions
  ├── Repository (fake)     ← ListingRepositoryFake (ultra-light)
  └── ID Provider (fake)    ← SequentialIdProvider
```

This means our tests validate the **actual collaboration** between business objects, not just isolated method calls.

### Why Not Solitary (Mockist/London School)?

Solitary unit tests mock every dependency of the unit under test. This creates problems:

- **Tests coupled to implementation**: Changing how a handler delegates to a domain service breaks tests, even if behavior is correct
- **False confidence**: Mocks return whatever you program them to — they can't catch integration bugs between real objects
- **Refactoring friction**: Extracting a method into a domain service requires rewriting mock setup
- **Testing the wrong thing**: You test that `pricingService.calculate()` was called with specific args, not that the price is correct

### Sources

- **Martin Fowler** — [Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html): Distinguishes classicist vs mockist schools
- **James Shore** — [Testing Without Mocks](https://www.jamesshore.com/v2/projects/nullables/testing-without-mocks): "Mocks can only check if dependencies' methods are being called. They can't check if they're being called correctly"
- **Uncle Bob** — [The Little Mocker](https://blog.cleancoder.com/uncle-bob/2014/05/14/TheLittleMocker.html): "Mostly I use stubs and spies. And I write my own, I don't often use mocking tools"

## The Boundary Rule: What Gets Faked

### The Network Boundary Principle

**Fake only what crosses a network, filesystem, or process boundary.** Everything else uses real implementations.

This aligns with hexagonal architecture: the **ports** (interfaces) that define infrastructure boundaries are the faking points. Everything inside the hexagon (entities, domain services, value objects) is real.

### Infrastructure Ports (FAKE)

These cross the network/filesystem boundary:

| Port Interface | Fake Implementation | Why Fake? |
|----------------|-------------------|-----------|
| `IListingRepository` | `ListingRepositoryFake` | Real one hits database — fake records save, returns injected value |
| `IPaymentGateway` | `PaymentGatewayFake` | Real one calls Stripe API — fake returns injected result |
| `IEmailService` | `EmailServiceFake` | Real one sends actual emails — fake records what was sent |
| `IFileStorage` | `FileStorageFake` | Real one writes to S3 — fake records upload call |
| `IIdProvider` | `SequentialIdProvider` | Real one generates UUIDs (non-deterministic) |
| `IDateProvider` | `FixedDateProvider` | Real one returns `new Date()` (non-deterministic) |

### Domain Logic (REAL — No Fakes)

These are pure business logic with zero I/O:

| Component | Why Real? |
|-----------|-----------|
| **Entities** | Contain single-entity business rules, state transitions. Pure in-memory objects. |
| **Domain Services** | Multi-entity coordination, complex calculations. Stateless, receive entities as params. |
| **Value Objects** | Immutable, equality by value. Pure data with behavior. |

**Critical**: Domain services do NOT have interfaces defined as ports. They are concrete classes injected directly into handlers. They need no fake because they perform no I/O.

### Architectural Alignment

```
┌─────────────────────────────────────────┐
│   Handlers (Application Layer)          │ ← Acceptance tests here
│   - Orchestrate workflow                │
│   - Coordinate domain + infrastructure  │
│   - Transaction boundaries              │
└─────────────────────────────────────────┘
         ↓ delegates to          ↓ calls through ports
┌──────────────────────┐  ┌──────────────────────┐
│  Domain Services     │  │  Infrastructure Ports │
│  (REAL in tests)     │  │  (FAKED in tests)     │
│  - Pure logic        │  │  - Repositories       │
│  - No I/O            │  │  - External APIs      │
│  - No interfaces     │  │  - File storage       │
└──────────────────────┘  └──────────────────────┘
         ↓ operates on
┌──────────────────────┐
│  Entities            │
│  (REAL in tests)     │
│  - State + rules     │
│  - Value objects     │
└──────────────────────┘
```

## Acceptance Tests vs E2E Tests

### Critical Distinction

| | Acceptance Tests | E2E Tests |
|---|---|---|
| **Purpose** | Validate business behavior | Validate technical integration |
| **Boundary** | Handler (application service) | Full stack (UI → DB) |
| **Speed** | Ultra-fast (milliseconds) | Slow (seconds) |
| **Dependencies** | Faked infrastructure | Real everything |
| **Focus** | Business rules and workflows | Wiring and deployment |
| **Effort** | 80% of testing budget | 5% of testing budget |

### ❌ WRONG: Acceptance Criteria Through GUI
```typescript
// DON'T DO THIS — testing business logic through GUI
it('should confirm booking', () => {
  cy.visit('/bookings')
  cy.get('[data-testid="book-button"]').click()
  cy.get('[data-testid="status"]').should('contain', 'confirmed')
})
```

### ✅ CORRECT: Acceptance Criteria Through Handlers
```typescript
// DO THIS — testing business behavior directly
describe('Feature: Request Booking', () => {
  it('should emit BookingRequested event', async () => {
    const eventStore = new BookingEventStoreFake()
    const handler = new RequestBookingCommandHandler(eventStore, new FixedClockStub())

    const dto = createRequestBookingDTOFixture()
    await handler.execute(dto)

    const events = await eventStore.getEvents(dto.bookingId)
    expect(events).toHaveLength(1)
    expect(events[0]._tag).toBe('BookingRequested')
  })
})
```

## Testing Hierarchy

### Primary: Handler / Acceptance Tests (80%)

- **Business behavior validation** through handler boundary
- **Ultra-fast execution** with faked infrastructure, real domain
- **Complete user story coverage** from acceptance criteria
- Validate specifications from PO / tech lead

### Secondary: Component Contract Tests (15%)

- **UI behavior only** — form interactions, validation display, callbacks
- **No business logic** — that's tested at handler level
- **Contract verification** — ensure UI calls correct callbacks with correct data
- Uses React Native Testing Library (RNTL) or Testing Library

Component tests are **unit tests for components**, NOT GUI tests:
- In-memory execution, no device/simulator
- Fast & isolated like handler tests
- Test WHAT the component does, not HOW it looks

NOTE: vi.fn() is permitted ONLY for component callback props (onSubmit, onPress, onChange).
This is NOT mocking business logic — it's verifying the UI contract: "did the component
call the right callback with the right data?" The business behavior behind that callback
is tested at the handler boundary with fakes.

### Minimal: Integration / E2E Tests (5%)

- **Critical user flows only**: registration, payment, core booking
- **Technical validation**: ensure full stack wires correctly
- **Deployment validation**: smoke tests post-deploy
- **Target**: <10 tests total

## Commit Tests & Deployment Pipeline

Commit tests (Dave Farley) are the **first gate** in the deployment pipeline. They must complete in **under 10 minutes**.

### Commit Stage Composition

1. **All unit tests** (acceptance + domain + component)
2. **Fast component tests** (no UI execution)
3. **Build process** (compile, create artifacts)
4. **Static analysis** (linting, type checking)
5. **Code quality gates** (coverage thresholds, complexity limits)

### What's NOT in Commit Tests

- No E2E tests (too slow)
- No real external dependencies
- No UI-driven test execution
- No performance/load tests

### Pipeline Flow

```
Developer: RED → GREEN → REFACTOR → Commit
                                       ↓
Pipeline Stage 1: Commit Tests (< 10 min)
  ├── All unit tests (acceptance + domain + component)
  ├── Build + type check + lint
  └── Coverage + quality gates
                                       ↓
Pipeline Stage 2: Acceptance Tests (automated, longer-running)
  └── Integration tests with real adapters (testcontainers)
                                       ↓
Pipeline Stage 3: Production Validation
  └── Smoke tests, performance, security
```

### Developer Workflow with Commit Tests

1. Write tests and implementation locally (TDD)
2. Run commit tests locally before push
3. Push to main branch triggers CI commit stage
4. If commit stage fails → fix within 10 minutes or revert
5. Green commit stage → pipeline continues to acceptance stage

## Test Organization

```
packages/modules/src/{module}/
├── slices/
│   └── {feature}/
│       ├── {feature}.handler.ts
│       ├── {feature}.handler.test.ts              # Acceptance tests (sociable)
│       └── fixtures/                                # Fixtures for query stubs
│           └── {entity}.fixture.ts
├── domain/
│   ├── entities/
│   │   └── {entity}.entity.ts                       # No separate test — tested via handlers
│   └── services/
│       ├── {service}.service.ts                     # No separate test unless complex algo
│       └── {service}.service.test.ts                # ONLY for complex calculations/algorithms
├── infrastructure/
│   ├── repositories/
│   │   ├── {entity}.repository.fake.ts
│   │   ├── {port}.failing-stub.ts                   # Saboteur for typed error scenarios
│   │   └── {service}.fake.ts
│   └── adapters/
│       └── postgres-{entity}.repository.ts
└── api/
    └── {feature}.integration.test.ts
```

### File Naming Convention

| Type | Suffix | Example |
|------|--------|---------|
| Unit tests (acceptance, domain) | `.test.ts` | `create-listing.handler.test.ts` |
| Integration tests | `.integration.test.ts` | `listing-api.integration.test.ts` |
| E2E tests | `.e2e.test.ts` | `booking-flow.e2e.test.ts` |

### Sociable Testing Implications

- **Entities have NO separate test files** — their business rules are exercised through handler acceptance tests
- **Domain services have NO separate test files** — unless they contain complex algorithms or calculations that benefit from isolated testing
- **If a domain service test exists**, it tests the algorithm itself, not its integration with handlers
