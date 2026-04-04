# Integration Tests

## Overview

Integration tests validate that **real adapters** (database, APIs, file storage) work correctly with our domain logic. They sit in the **5% budget** alongside E2E tests, targeting critical technical integration points only.

## Integration Strategy: Two Clear Levels (ADR-0016)

Integration tests validate that **real adapters** work correctly — the secondary adapters that cross network/filesystem boundaries. No contract tests needed: ultra-light test fakes have no behavior to prove equivalent to real adapters. Integration tests on real adapters provide infrastructure confidence directly.

| Strategy | What it validates | Priority | Count |
|----------|------------------|----------|-------|
| **Adapter integration tests** (testcontainers) | Real DB queries, DTO↔domain mapping, SQL subtleties, constraints | Primary | Majority of integration budget |
| **API smoke tests** (supertest) | HTTP wiring, middleware, serialization, status codes | Secondary | Handful per module |

## When to Write Integration Tests

### Adapter Integration Tests (Primary)

- **Repository adapters**: Test real DB queries, DTO↔domain mapping, constraints, serialization
- **External API clients**: Test real HTTP calls, response parsing, error handling
- **Message queue producers/consumers**: Test serialization, routing, delivery guarantees
- **File storage adapters**: Test upload/download against real storage (or localstack)

### API Smoke Tests (Secondary)

- **Route registration**: Endpoint exists and is wired correctly
- **Auth middleware**: Protected routes reject unauthenticated requests
- **Error format**: Invalid input returns RFC 7807 Problem Details
- **Serialization**: Response shape matches DTO contract

## When NOT to Write Integration Tests

- **Business logic**: Tested at use case level with fakes (80% budget)
- **UI behavior**: Tested with component tests (15% budget)
- **Every CRUD operation**: Only test complex queries or edge cases
- **Happy paths already covered by acceptance tests**: Avoid duplication

## Two Clear Levels, No Overlap (ADR-0016)

```
LEVEL 1 — UNIT TESTS (fast, commit stage):
  SUT: Primary Port (use case execute/handle)
  Traverses: Real domain services + real entities
  Doubles: Ultra-light fakes for infra ports
  Covers: Business behavior, acceptance criteria

LEVEL 2 — INTEGRATION TESTS (targeted, CI pipeline):
  SUT: Secondary Adapter directly (e.g., PostgresListingRepository)
  Traverses: Real DB via testcontainers
  Doubles: None (real implementations)
  Covers: DTO↔domain mapping, SQL subtleties, constraints, serialization
```

Each level has a clear, non-overlapping role. No contract tests, no shared test factory, no two-suite pattern. Ultra-light fakes have no internal logic to prove equivalent to real adapters — they're nearly inert.

## Repository Integration with Testcontainers

The primary integration testing strategy — test real adapters directly against real infrastructure:
```typescript
// packages/modules/src/listing/infrastructure/repositories/postgres-listing.repository.integration.test.ts
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest'
import { PostgreSqlContainer } from '@testcontainers/postgresql'
import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import { PostgresListingRepository } from './postgres-listing.repository'
import { createListingFixture } from '@listing/slices/create-listing/fixtures/listing.fixture'

describe('PostgresListingRepository Integration', () => {
  let container: StartedPostgreSqlContainer
  let db: PostgresDatabase
  let repository: PostgresListingRepository

  beforeAll(async () => {
    container = await new PostgreSqlContainer().start()
    const client = postgres(container.getConnectionUri())
    db = drizzle(client)
    await runMigrations(db)
    repository = new PostgresListingRepository(db)
  }, 30_000) // Testcontainer startup can take time

  afterAll(async () => {
    await container.stop()
  })

  beforeEach(async () => {
    await db.delete(listingsTable) // Clean slate per test
  })

  it('should handle unique constraint violation', async () => {
    const listing = createListingFixture()
    await repository.save(listing)

    await expect(repository.save(listing))
      .rejects.toThrow(/duplicate|constraint/i)
  })

  it('should filter by status with correct SQL', async () => {
    const draft = createListingFixture({ status: 'draft' })
    const published = createListingFixture({ status: 'published' })
    await repository.save(draft)
    await repository.save(published)

    const results = await repository.findByStatus('published')

    expect(results).toHaveLength(1)
    expect(results[0].props.id).toBe(published.props.id)
  })
})
```

## API Smoke Tests

Thin layer covering HTTP-specific concerns only. Business behavior is already validated by unit tests at the use case boundary — these just verify the wiring:
```typescript
// packages/modules/src/listing/api/listings-api.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import supertest from 'supertest'
import { createApp } from '@listing/app'

describe('Listings API Smoke', () => {
  let app: NestApplication
  let request: supertest.SuperTest<supertest.Test>

  beforeAll(async () => {
    app = await createApp({ useTestDatabase: true })
    request = supertest(app.getHttpServer())
  })

  afterAll(async () => {
    await app.close()
  })

  it('should return 201 on valid create', async () => {
    const response = await request
      .post('/api/listings')
      .send({
        spaceType: 'parking',
        dimensions: { length: 5, width: 2.5 },
        hourlyRate: 3.50
      })
      .expect(201)

    expect(response.body.id).toBeDefined()
    expect(response.body.status).toBe('draft')
  })

  it('should return RFC 7807 Problem Details on invalid input', async () => {
    const response = await request
      .post('/api/listings')
      .send({ spaceType: 'parking', hourlyRate: -5 })
      .expect(400)

    expect(response.body.type).toBeDefined()
    expect(response.body.title).toBeDefined()
    expect(response.body.status).toBe(400)
    expect(response.body.detail).toBeDefined()
  })
})
```

## Pitfall: Event Listener Registration Order

When using `waitForEvents()` or `once()` in integration tests with real event emitters, register the listener **before** the operation that triggers the event. Fast jobs may complete before the listener attaches, causing tests to hang waiting for events that already fired.

```typescript
// ✅ Listener registered BEFORE the operation
const eventPromise = once(emitter, 'booking.confirmed')
await handler.execute(command)
const [event] = await eventPromise

// ❌ Operation fires before listener is attached — may hang
await handler.execute(command)
const [event] = await once(emitter, 'booking.confirmed') // too late
```

Source: [Matteo Collina](https://www.linkedin.com/posts/matteocollina_here-is-what-i-taught-opus-46-today-share-7429948822463778816-AgrE)

## Key Principles

- **Two clear levels**: Unit tests with ultra-light fakes (business behavior) + integration tests on real adapters (infrastructure correctness)
- **API smoke tests**: Only for HTTP-specific concerns integration tests can't reach
- **Isolate from other tests**: Each test cleans up its own data
- **Use real dependencies**: The whole point is testing real adapters
- **Keep the count low**: <10 integration tests per module
- **Run separately**: `pnpm test:integration` (not in watch mode)
- **Don't duplicate business logic testing**: That's the acceptance tests' job
