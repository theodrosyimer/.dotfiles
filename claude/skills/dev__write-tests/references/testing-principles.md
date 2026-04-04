# Testing Strategy with TDD & Fake-Driven Development

## Overview

This document provides comprehensive guidance on **test-driven development (TDD)** using **fake-driven testing philosophy**. The approach validates acceptance criteria at the application layer (handler boundary) using ultra-fast **sociable unit tests** with fake implementations for infrastructure ports only, following the classicist TDD approach.

**Testing framework: Vitest** — All tests run on Vitest. Never use Jest.

## Core Principles

### 1. Sociable Unit Testing at Handler Boundary

Our acceptance tests are **sociable unit tests** (Fowler): they exercise the handler with **real domain services and real entities**, faking only infrastructure ports that cross the network boundary. This is the **classicist** approach (London school tests interactions; we test outcomes).

### 2. The Boundary Rule: What Gets Faked

```
ULTRA-LIGHT FAKE (infrastructure ports — crosses network/filesystem):
  Repositories (IListingRepository → ListingRepositoryFake)
  External APIs (IPaymentGateway → PaymentGatewayFake)
  ID providers (IIdProvider → SequentialIdProvider)
  Date providers (IDateProvider → FixedDateProvider)
  File storage (IFileStorage → FileStorageFake)
  Email services (IEmailService → EmailServiceFake)

REAL (domain logic — pure functions, no I/O):
  Entities (BookingEntity, SpaceListingEntity)
  Domain services (BookingPricingService, ValidationService)
  Value objects (Money, DateRange, Address)

SIGNAL YOUR FAKE IS TOO COMPLEX:
  It declares a Map or array of stored values
  It needs its own tests to verify correctness
  It reimplements repository logic (filtering, searching)
```

**Why?** Domain services are pure business logic with zero infrastructure dependencies. They receive entities as parameters and return results. Faking them would test nothing — you'd be testing your fake, not your business rules.

### 3. Testing Hierarchy

| Focus | Effort | What | Speed |
|-------|--------|------|-------|
| **Handler / Acceptance Tests** | 80% | Business behavior at handler boundary with fakes | Ultra-fast (ms) |
| **Component Contract Tests** | 15% | UI behavior, form interactions, callbacks (RNTL) | Fast (ms) |
| **Integration / E2E Tests** | 5% | Critical flows, deployment validation | Slow (s) |

### 4. Test Doubles Taxonomy (Meszaros)

| Double | Purpose | When to Use |
|--------|---------|-------------|
| **Fake (test)** | Ultra-light — records save input, returns injected value. Nearly zero logic | Command handlers: repositories, gateways |
| **Fake (demo)** | Working in-memory implementation (Map, filtering) for demos | Frontend DI container, stakeholder demos — **never in tests** |
| **Stub** | Returns canned answers, no logic | Query handlers, gateway DTOs, fixture-driven responses |
| **Spy** | Wraps real implementation, records calls | Verify side effects on real services (email sent, event published) |
| **Dummy** | Fills a parameter, never used | Required constructor args not relevant to test |
| **Mock** | AVOID — pre-programmed expectations | Couples tests to implementation, breaks on refactor |

### 5. Naming Convention for Test Doubles (ADR-0016)

```
TEST FAKES (ultra-light — no InMemory prefix):
  ListingRepositoryFake         ← Suffix Fake, no InMemory prefix
  BookingRepositoryFake         ← Suffix Fake
  PaymentGatewayFake            ← Suffix Fake
  FileStorageFake               ← Suffix Fake
  EmailServiceFake              ← Suffix Fake

DEMO FAKES (stateful — InMemory prefix, for frontend dev only):
  InMemoryListingRepository     ← InMemory prefix signals stateful impl
  InMemoryBookingRepository     ← Used in frontend DI container, NEVER in tests

ALREADY ULTRA-LIGHT (no change needed):
  SequentialIdProvider          ← "Sequential" already explicit
  FixedDateProvider             ← "Fixed" already explicit
  FixedClockStub                ← Already ultra-light

STUBS (always suffix):
  GetListingQueryHandler         ← Returns canned fixture data
  SpaceListingGatewayStub       ← Returns canned DTO
  PaymentGatewayFailingStub     ← Saboteur — throws typed expected errors

ERROR MAPS (always ExpectedErrors suffix):
  paymentGatewayExpectedErrors  ← Co-located with port interface in domain layer
  fileStorageExpectedErrors     ← Typed error names for FailingStub constructor
```

## IMPORTANT Tips

> An important pattern discovered during testing: When using waitForEvents() or once(), the listener must be registered before the operation that might trigger the event. Otherwise, fast jobs might complete before the listener is attached, causing tests to hang indefinitely waiting for events that already occurred. source: [Matteo Collina](https://www.linkedin.com/posts/matteocollina_here-is-what-i-taught-opus-46-today-share-7429948822463778816-AgrE?utm_source=share&utm_medium=member_ios&rcm=ACoAAD_aqRABVXncVe6JaMWxOYb03qO2ymAO-8k)

## Quick Reference

### What NOT to Do
- Do not test business logic through GUI
- Do not use mocks (vi.fn()) instead of fakes — EXCEPT for component callback props
- Do not fake domain services (they're pure logic)
- Do not write production code before tests
- Do not test implementation details
- Do not create slow, brittle E2E tests for acceptance criteria
- Do not use Jest (use Vitest)
- Do not use floating literal objects in tests — use `create` prefix + `Fixture` suffix factories/builders
- Do not create fakes with Map storage or internal state — use ultra-light fakes (ADR-0016)

### File Naming Convention

| Type | Suffix | Example |
|------|--------|---------|
| Unit tests | `.test.ts` | `create-listing.handler.test.ts` |
| Integration tests | `.integration.test.ts` | `listing-api.integration.test.ts` |
| E2E tests | `.e2e.test.ts` | `booking-flow.e2e.test.ts` |

### Test Data Naming Convention

| Pattern | Example |
|---------|---------|
| Factory function | `createListingFixture({ hourlyRate: 5 })` |
| Builder | `createBookingFixture().forListing(id).confirmed().build()` |
| FailingStub | `new PaymentGatewayFailingStub('cardDeclined')` |
