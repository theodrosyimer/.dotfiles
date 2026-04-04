---
name: caching
description:
  Add a caching layer to an existing infrastructure adapter or NestJS endpoint. Covers Redis-backed
  cache adapters implementing existing ports, TanStack Query staleTime configuration, Cache-Control
  headers in NestJS, and Redis client tracking for distributed invalidation. Use when adding caching
  to an existing repository, external API client, or API endpoint — NOT for new features from
  scratch (use the testing skill first).
---

# Caching — Skill

Add a caching layer to an existing infrastructure adapter or API endpoint, following the
port/adapter pattern. Caching is always infrastructure — it wraps an existing port implementation,
never invades the domain or use case layer.

## When to Use This Skill

- Adding Redis caching to an existing repository adapter
- Adding a cache wrapper around an external API client (HTTP port)
- Configuring `Cache-Control` headers on a NestJS endpoint
- Setting up Redis client tracking for distributed cache invalidation
- Configuring `staleTime` and `invalidateQueries` correctly in TanStack Query hooks
- Reviewing an adapter for caching opportunities

## When NOT to Use This Skill

- Building a new feature from scratch — use the `testing` skill first, then come back here
- Deciding whether to cache at all — that is an architectural question, check the knowledge doc
  first

## References

- **[references/caching-at-scale-layers-patterns-and-anti-patterns.md](references/caching-at-scale-layers-patterns-and-anti-patterns.md)**
  — Full layer stack, stampede pattern, Redis client tracking, decision matrix

---

## Process

### Step 1 — Identify the target

Before writing any code, identify:

1. **What is being cached?** — repository query, external API response, rendered page fragment, HTTP
   response
2. **What port/interface does it implement?** — the cache adapter must implement the same interface
   as the existing adapter
3. **What is the cache store?** — Redis (preferred, already in stack) or in-process Map (tests/dev
   only)
4. **What is the invalidation trigger?** — command that mutates the data (save, delete, update)

```
DISCOVERY QUESTIONS

  Port interface:     IListingRepository? IWeatherApiClient?
  Existing adapter:   PostgresListingRepository? FetchWeatherApiClient?
  Cache store:        Redis (prod) / Map (test/dev)
  Invalidation:       Which use cases mutate this data?
  TTL:                How stale is acceptable? (seconds)
```

### Step 2 — Implement the cache adapter

The cache adapter wraps the real adapter and implements the same port. It is never injected into
domain or use case code directly — the DI container wires it transparently.

```typescript
// infrastructure/cache/CachedListingRepository.ts

import type { IListingRepository } from '../../domain/ports/IListingRepository'
import type { ICache } from '../ports/ICache'
import type { SpaceListingEntity } from '../../domain/entities/SpaceListingEntity'

export class CachedListingRepository implements IListingRepository {
  constructor(
    private readonly inner: IListingRepository, // real adapter (Postgres, etc.)
    private readonly cache: ICache,
    private readonly ttlSeconds: number = 300,
  ) {}

  async findById(id: string): Promise<SpaceListingEntity | null> {
    const key = `listing:${id}`
    const cached = await this.cache.get<SpaceListingEntity>(key)
    if (cached) return cached

    const result = await this.inner.findById(id)
    if (result) await this.cache.set(key, result, this.ttlSeconds)
    return result
  }

  async save(listing: SpaceListingEntity): Promise<void> {
    await this.inner.save(listing)
    // Invalidate on mutation — never serve stale after a write
    await this.cache.delete(`listing:${listing.props.id}`)
  }

  async delete(id: string): Promise<void> {
    await this.inner.delete(id)
    await this.cache.delete(`listing:${id}`)
  }
}
```

### Step 3 — Wire in the DI container

Swap the cache adapter in only in the production container. The test/dev container keeps ultra-light
fakes (`ListingRepositoryFake`) — no cache layer needed.

```typescript
// infrastructure/containers/ProductionContainer.ts

import { CachedListingRepository } from '../cache/CachedListingRepository'
import { PostgresListingRepository } from '../adapters/PostgresListingRepository'
import { RedisCache } from '../cache/RedisCache'

const redisCache = new RedisCache(redisClient)
const postgresRepo = new PostgresListingRepository(db)

const listingRepository = new CachedListingRepository(
  postgresRepo,
  redisCache,
  300, // 5 min TTL
)

// Use cases receive the same IListingRepository interface — unaware of the cache
const getListingQueryHandler = new GetListingQueryHandler(listingRepository)
```

```typescript
// infrastructure/containers/FakeContainer.ts — UNCHANGED

// ListingRepositoryFake is ultra-light — no cache layer needed in tests.
const listingRepository = new ListingRepositoryFake()
```

### Step 4 — Redis client tracking (distributed invalidation)

When running multiple API instances, use Redis client tracking so all instances evict their local
copy when a key is invalidated.

```typescript
// infrastructure/cache/RedisCache.ts

import { createClient } from 'redis'

export class RedisCache implements ICache {
  private localCache = new Map<string, unknown>()
  private subscriber: ReturnType<typeof createClient>

  constructor(private readonly redis: ReturnType<typeof createClient>) {
    this.subscriber = redis.duplicate()
    this.enableClientTracking()
  }

  private async enableClientTracking() {
    await this.subscriber.connect()
    // Redis notifies this client when a tracked key is invalidated
    await this.subscriber.sendCommand(['CLIENT', 'TRACKING', 'ON', 'BCAST'])
    this.subscriber.on('invalidate', (keys: string[]) => {
      keys.forEach((key) => this.localCache.delete(key))
    })
  }

  async get<T>(key: string): Promise<T | null> {
    // Check local in-process cache first (microsecond)
    if (this.localCache.has(key)) return this.localCache.get(key) as T

    // Fall through to Redis (millisecond)
    const raw = await this.redis.get(key)
    if (!raw) return null

    const value = JSON.parse(raw) as T
    this.localCache.set(key, value) // populate local cache
    return value
  }

  async set<T>(key: string, value: T, ttlSeconds: number): Promise<void> {
    await this.redis.setEx(key, ttlSeconds, JSON.stringify(value))
    this.localCache.set(key, value)
  }

  async delete(key: string): Promise<void> {
    await this.redis.del(key)
    this.localCache.delete(key)
    // Redis client tracking notifies other instances automatically
  }
}
```

### Step 5 — NestJS Cache-Control headers (HTTP layer)

For public or semi-public API endpoints, add `Cache-Control` via an interceptor — never in
controllers.

```typescript
// infrastructure/interceptors/CacheControlInterceptor.ts

import {
  Injectable,
  type NestInterceptor,
  type ExecutionContext,
  type CallHandler,
} from '@nestjs/common'
import type { Observable } from 'rxjs'
import { tap } from 'rxjs/operators'

@Injectable()
export class CacheControlInterceptor implements NestInterceptor {
  constructor(private readonly maxAge: number = 60) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    return next.handle().pipe(
      tap(() => {
        const response = context.switchToHttp().getResponse()
        response.setHeader(
          'Cache-Control',
          `public, max-age=${this.maxAge}, stale-while-revalidate=30`,
        )
      }),
    )
  }
}

// Apply at controller level (not globally — only public endpoints)
@Controller('listings')
@UseInterceptors(new CacheControlInterceptor(300)) // 5 min for listings
export class ListingsController {}
```

### Step 6 — TanStack Query configuration (frontend)

Configure `staleTime` deliberately. Never leave it at `0` for data that doesn't change per-request.

```typescript
// slices/listings/hooks/useGetListing.ts

export function useGetListing(id: string) {
  return useQuery({
    queryKey: ['listings', id],
    queryFn: () => getListingQueryHandler.execute(id),
    staleTime: 5 * 60 * 1000, // 5 min — treat as fresh, no background refetch
    gcTime: 10 * 60 * 1000, // 10 min — keep in memory after becoming unused
  })
}

// slices/listings/hooks/useUpdateListing.ts
export function useUpdateListing() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: updateListingCommandHandler.execute.bind(updateListingCommandHandler),
    onSuccess: (_, variables) => {
      // Targeted invalidation — only the affected listing
      queryClient.invalidateQueries({ queryKey: ['listings', variables.id] })
    },
  })
}
```

---

## Decision Matrix

```
DECISION — Which cache layer to add?

  SLOW EXTERNAL API (> 300ms):
    ✅ Cache adapter wrapping the HTTP port (Step 2-3)
    ✅ TTL based on data freshness requirements
    ❌ Don't cache inside the use case

  DATABASE QUERY (hot read path):
    ✅ CachedRepository wrapping the DB adapter (Step 2-3)
    ✅ Redis client tracking for multi-instance invalidation (Step 4)
    ❌ Don't add SELECT caching inside the repository method itself

  PUBLIC API ENDPOINT:
    ✅ Cache-Control headers via NestJS interceptor (Step 5)
    ✅ CDN or reverse proxy will respect these headers
    ❌ Don't cache authenticated/personalized endpoints this way

  FRONTEND REMOTE STATE:
    ✅ staleTime in useQuery (Step 6)
    ✅ invalidateQueries in useMutation onSuccess (Step 6)
    ❌ Don't duplicate in Zustand — TanStack Query owns remote state

  REQUEST DEDUPLICATION (stampede):
    ✅ TanStack Query handles this automatically on the frontend
    ✅ For server-side: [layered-loader](https://github.com/kibertoad/layered-loader) pattern at the adapter layer
    ❌ Don't implement this inside a use case
```

---

## Quick Checklist

- [ ] Cache adapter implements the same port as the real adapter
- [ ] Fake container is unchanged — ultra-light `*RepositoryFake` stays as-is (no cache wrapper)
- [ ] Invalidation is triggered on every mutating operation (`save`, `delete`, `update`)
- [ ] Redis client tracking enabled for multi-instance deployments
- [ ] `staleTime` set deliberately on all `useQuery` calls
- [ ] `invalidateQueries` called in `onSuccess` of all relevant mutations
- [ ] No cache logic inside use cases, entities, or domain services
