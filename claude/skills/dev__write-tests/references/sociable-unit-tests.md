# Sociable Unit Tests: Deep Dive

## Overview

Sociable unit tests exercise a **cluster of real collaborating objects** while faking only external boundaries. This is the classicist (Detroit/Chicago school) approach to TDD, and it is our default testing strategy at the handler boundary.

## Classicist vs Mockist Schools

### Classicist (Our Approach)

The classicist school, championed by Kent Beck and advocated by Martin Fowler, tests **behavior outcomes** using real collaborators:

- Handler calls **real** domain service
- Domain service operates on **real** entity
- Only infrastructure ports are **faked**
- Assert on **results and state**, not on method calls

```typescript
// Classicist: verify OUTCOME
const booking = await createBookingHandler.execute(request)
expect(booking.totalPrice).toBe(7.00)  // Correct result?
expect(booking.status).toBe('confirmed')  // Correct state?
```

### Mockist (London School — Not Our Approach)

The mockist school, championed by Steve Freeman and Nat Pryce, tests **interactions** between objects using mocks:

- Every dependency is mocked
- Assert on **method calls and arguments**
- Tests are coupled to implementation structure

```typescript
// Mockist: verify INTERACTION (we don't do this)
expect(mockPricingService.calculate).toHaveBeenCalledWith(listing, 2)
expect(mockRepository.save).toHaveBeenCalledWith(expect.objectContaining({ status: 'confirmed' }))
```

### Why Classicist Wins for Us

| Aspect | Classicist (Sociable) | Mockist (Solitary) |
|--------|----------------------|-------------------|
| **Refactoring safety** | High — rename/extract freely | Low — breaks mock setup |
| **False positives** | Rare — real collaboration | Common — mocks always "work" |
| **Test readability** | Clear: input → output | Noisy: mock setup dominates |
| **Maintenance cost** | Low — stable on refactor | High — coupled to structure |
| **Integration confidence** | High — real object graph | Low — each mock is an assumption |

## The Network Boundary Rule

### Principle

> **Fake only what crosses a network, filesystem, or process boundary.**

This single rule determines what to fake and what to keep real.

### Decision Flowchart

```
Does this dependency perform I/O?
├── YES (network, filesystem, process) → FAKE IT
│   Examples: Database, HTTP API, S3, SMTP, UUID generation, system clock
│
└── NO (pure computation, in-memory) → USE REAL INSTANCE
    Examples: Entities, domain services, value objects, validators
```

### Why Non-Determinism is Also Faked

`IIdProvider` and `IDateProvider` don't cross a network, but they produce non-deterministic output. Faking them gives tests:

- **Deterministic assertions**: `expect(id).toBe('fake-id-1')`
- **Reproducible scenarios**: Fixed date for time-dependent business rules
- **Snapshot-friendly output**: Same IDs across test runs

## Sociable Test Anatomy

### What the Test Exercises

```
createBookingHandler.execute(request)
  │
  ├── [REAL] BookingPricingService.calculateTotalPrice(booking, space, customer)
  │     ├── [REAL] booking.getDurationInHours()         ← entity method
  │     ├── [REAL] space.getHourlyRate()                ← entity method
  │     └── [REAL] customer.isPremiumMember()           ← entity method
  │
  ├── [REAL] BookingEntity constructor                  ← business rules validation
  │     └── [REAL] booking.isWithinBusinessHours()      ← entity method
  │
  ├── [FAKE] bookingRepository.save(booking)            ← records to public field
  ├── [FAKE] idProvider.generate()                      ← returns 'fake-id-1'
  └── [FAKE] emailService.send(confirmation)            ← records to array
```

A single acceptance test validates the **entire business rule chain** from handler through domain services and entities. If any business rule is wrong, the test fails.

### What a Mockist Version Would Miss

With mocks, you'd verify that `pricingService.calculate` was called — but NOT that the price is correct. You'd verify that `repository.save` was called — but NOT that the saved entity has valid state. The mocks always return what you program them to, hiding real bugs.

## Common Pitfalls

### ❌ Faking Domain Services

```typescript
// WRONG: This tests nothing useful
const pricingService = { calculateTotalPrice: () => 7.00 } // Mock always returns 7
const booking = await handler.execute(request)
expect(booking.totalPrice).toBe(7.00) // Of course it's 7, you hardcoded it!
```

### ❌ Using vi.fn() for Infrastructure

```typescript
// WRONG: Mock instead of fake
const mockRepo = { save: vi.fn(), findById: vi.fn().mockResolvedValue(listing) }
// Fragile: tied to method signature, doesn't catch real persistence bugs
```

### ✅ Proper Sociable Test

```typescript
// CORRECT: Real domain, faked infrastructure
const repo = new ListingRepositoryFake()
const pricingService = new BookingPricingService() // REAL
const handler = new CreateBookingCommandHandler(repo, idProvider, pricingService, emailFake)

const booking = await handler.execute(request)
expect(booking.totalPrice).toBe(7.00) // Real calculation!
```

## Sources

- **Martin Fowler** — [Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
- **Martin Fowler** — [Unit Test (sociable vs solitary)](https://martinfowler.com/bliki/UnitTest.html)
- **James Shore** — [Testing Without Mocks: A Pattern Language](https://www.jamesshore.com/v2/projects/nullables/testing-without-mocks)
- **Uncle Bob** — [The Little Mocker](https://blog.cleancoder.com/uncle-bob/2014/05/14/TheLittleMocker.html)
- **Gerard Meszaros** — *xUnit Test Patterns* (test doubles taxonomy)
- **Kent Beck** — *Test-Driven Development: By Example* (classicist TDD origin)
