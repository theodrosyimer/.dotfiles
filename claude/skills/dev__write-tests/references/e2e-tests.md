# E2E Tests (Minimal Strategy)

## Overview

E2E tests validate **critical user flows** end-to-end. They are the most expensive tests to write and maintain, so we keep them to an absolute minimum — **<10 tests total** across the entire application.

## When to Write E2E Tests

Only for **mission-critical flows** where failure means direct business impact:

- **User registration / authentication** — Can users get into the system?
- **Core payment flow** — Does money move correctly?
- **Primary booking flow** — Does the core business process work end-to-end?
- **Deployment smoke test** — Did the deployment break anything fundamental?

## When NOT to Write E2E Tests

- **Acceptance criteria** — Tested at use case boundary (80% budget)
- **Form validation** — Tested in component tests (15% budget)
- **Edge cases** — Tested in unit tests
- **Visual appearance** — Manual exploratory testing
- **Every CRUD operation** — Massive overkill

## E2E Test Structure

```typescript
// e2e/critical-flows/booking-flow.e2e.test.ts
import { describe, it, expect } from 'vitest'

describe('Critical Flow: Complete Booking', () => {
  it('should allow user to register, find space, and book', async () => {
    // 1. Register user
    const user = await registerTestUser()

    // 2. Find available listing
    const listings = await getPublishedListings()
    expect(listings.length).toBeGreaterThan(0)

    // 3. Create booking
    const booking = await createBooking({
      listingId: listings[0].id,
      userId: user.id,
      period: { start: tomorrow10am, end: tomorrow12pm }
    })

    expect(booking.status).toBe('confirmed')

    // 4. Verify email sent (check test inbox)
    const email = await waitForEmail(user.email, { timeout: 5000 })
    expect(email.subject).toContain('Booking Confirmed')
  })
})
```

## Deployment Smoke Tests

Post-deployment validation that core functionality works:

```typescript
// e2e/smoke/health-check.e2e.test.ts
describe('Deployment Smoke Tests', () => {
  it('should respond to health check', async () => {
    const response = await fetch(`${BASE_URL}/health`)
    expect(response.status).toBe(200)
  })

  it('should serve the main page', async () => {
    const response = await fetch(BASE_URL)
    expect(response.status).toBe(200)
  })

  it('should authenticate with valid credentials', async () => {
    const response = await authenticate(testCredentials)
    expect(response.token).toBeDefined()
  })
})
```

## Key Principles

- **Fewer is better**: <10 E2E tests total. Each one you add costs maintenance.
- **Test business flows, not features**: One test covers an entire user journey.
- **Run separately**: Not in the commit stage. Run in pipeline stage 2+.
- **Flakiness budget**: If an E2E test is flaky more than 2% of the time, delete it or fix the underlying issue.
- **Don't test business rules here**: That's the acceptance tests' job.

## E2E vs Acceptance Tests Reminder

| | Acceptance | E2E |
|---|---|---|
| Tests business rules? | ✅ Yes | ❌ No — that's already tested |
| Tests full stack wiring? | ❌ No — uses fakes | ✅ Yes — real everything |
| Speed | Milliseconds | Seconds to minutes |
| Count | Hundreds | <10 |
| Runs in | Commit stage | Post-commit pipeline |
