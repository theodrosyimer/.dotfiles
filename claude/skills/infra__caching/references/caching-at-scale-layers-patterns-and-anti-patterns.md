# Caching at Scale — Layers, Patterns, and Anti-Patterns

> **Source**: Mateo & Luka — [Caching Discussion: To Cache or Not to Cache](https://www.youtube.com/watch?v=tnidZ_9BH1w)
>
> **Key Insight**: Caching is not fundamentally hard — HTTP caching and Redis have been standardized and battle-tested. The real problem is that most teams either underestimate the nuance required to implement it correctly, or throw hardware at the problem instead. Don't reinvent caching; sit on the shoulders of giants.

---

## 1. Why Companies Avoid Caching (And Why That's a Mistake)

The two most commonly cited fears are serving one user's private data to another, and stale data reaching the client. Both are legitimate — but the underlying assumption driving these fears is wrong: that a system can be kept perfectly consistent in real time over a large distributed network.

Mateo frames this directly: bank account balances are cached values. The "available to spend" figure is computed from other data and may lag reality. Banks now surface this explicitly — two figures, not one. The takeaway is that **stale data and eventual consistency are the norm, not an exception to guard against**. Design for them.

The second reason companies skip caching is more practical: adding it means adding a component with its own operational cost. The honest diagnosis is that **most enterprise teams lack the deep knowledge to implement it correctly**, so they buy more hardware instead. Caching requires understanding distributed system failure modes, cache key design, and tooling like Redis — knowledge that simply isn't common.

```
DECISION — To Cache or Not to Cache

CONTEXT: High traffic, repeated expensive computations or slow external calls

ANTI-PATTERN:
  ❌ Add more hardware to absorb load
     → Treats the symptom, not the cause
     → Expensive indefinitely
     → Still hits limits eventually

CORRECT APPROACH:
  ✅ Cache computationally expensive responses
  ✅ Cache slow external API responses (> ~500ms round-trip)
  ✅ Cache rendered pages/components
  ✅ Accept eventual consistency as the design norm, not a bug
```

---

## 2. The Caching Layer Stack

There are several distinct levels where caching can be applied. Each targets a different cost centre.

```
CACHING LAYERS — Outer to Inner

  ┌──────────────────────────────────────────────┐
  │  1. CDN (Edge)                               │
  │     Static assets: images, CSS, JS bundles   │
  │     Public pages                             │
  └──────────────────────┬───────────────────────┘
                         │
  ┌──────────────────────▼───────────────────────┐
  │  2. HTTP Cache — External Edge               │
  │     (e.g., Cloudflare, CDN with HTML cache)  │
  │     Public responses, personalized with      │
  │     cache tags / surrogate keys              │
  └──────────────────────┬───────────────────────┘
                         │
  ┌──────────────────────▼───────────────────────┐
  │  3. HTTP Cache — Internal Cluster            │
  │     (e.g., Nginx, Varnish, or app-side)      │
  │     For data sensitivity or compliance       │
  │     reasons; still HTTP-spec-compliant       │
  └──────────────────────┬───────────────────────┘
                         │
  ┌──────────────────────▼───────────────────────┐
  │  4. Application / In-Process Cache           │
  │     (e.g., Redis, Memcached, local memory)   │
  │     Query results, rendered components,      │
  │     expensive computation results            │
  └──────────────────────────────────────────────┘

WHAT TO CACHE AT EACH LAYER:
  CDN              → Everything static — never re-derive
  HTTP External    → Public responses, personalised fragments
  HTTP Internal    → Sensitive data you control access to
  Application      → Query results, third-party API responses,
                     rendered pages (Next.js component cache)
```

The CDN tier is non-negotiable. If you haven't been putting static assets in a CDN for the past 20 years, the answer is clear: do it now. Static assets change only through automation, so the invalidation problem is trivially solved.

---

## 3. The Cache Stampede Problem (and Deduplication)

When a cached entry expires, all concurrent requests for that resource can hit the backend simultaneously — the "thundering herd" or cache stampede. This is one of the most common failure modes in production caching, and one of the least understood.

```
CACHE STAMPEDE — What Happens at Expiry

  Cache expires at T=0:
     │
     ├─ Request A → cache MISS → hits backend
     ├─ Request B → cache MISS → hits backend  ← same data, same work
     ├─ Request C → cache MISS → hits backend  ← same data, same work
     └─ ...N concurrent requests → backend collapses

  SOLUTION: Request Coalescing / Deduplication

     │
     ├─ Request A → cache MISS → starts backend call (key: hash of params)
     ├─ Request B → cache MISS → same hash → WAIT on A's in-flight request
     ├─ Request C → cache MISS → same hash → WAIT on A's in-flight request
     │
     └─ A returns → B and C receive same result
        Async process refreshes cache → swaps in new value
```

Mateo describes a library he built (`async-cache-dedup`) that solves this by computing a stable JSON hash of the request parameters and using it as a deduplication key. If two in-flight requests share the same hash, only one goes to the origin. The fix is also being integrated into the Platformatic API gateway as an on/off flag — no manual implementation needed.

The same deduplication logic is present in **Mercurius** (the GraphQL layer in the Fastify ecosystem), making it available out of the box in the GraphQL caching layer.

---

## 4. HTTP Caching: Client-Side vs Server-Side Placement

A key architectural decision for HTTP caching is **where in the request path the cache sits**.

```
PLACEMENT DECISION — HTTP Cache Position

  OPTION A: Server-side cache
    Client → [Network roundtrip] → Server [cache here] → Backend
    ✅ Centralized
    ❌ Still pays the network cost to reach the server

  OPTION B: Client-side cache (recommended)
    Client [cache here] → Server
    ✅ Eliminates network roundtrip entirely for cache hits
    ✅ Aligns with how HTTP spec is designed (client as proxy)
    ✅ Each client or client group has an independent cache
    ❌ Cache is distributed; invalidation is more complex
```

In Fastify/Platformatic, the HTTP client-side cache is implemented to act as a proxy — exactly as the HTTP spec intends. This means the cache sits on the caller's side, and repeated calls to the same URL with the same semantics return cached data without touching the network.

---

## 5. Redis-Backed Distributed Cache with Client Tracking

For application-level caching in distributed systems, a two-tier approach using Redis provides both performance and invalidation correctness.

```
TWO-TIER CACHE ARCHITECTURE

  ┌─────────────────────────────────────────────────────┐
  │  App Process (Node A)                               │
  │  ┌───────────────────┐                              │
  │  │ Local in-memory   │ ← Layer 1: ultra-fast         │
  │  │ cache             │   (microsecond reads)         │
  │  └─────────┬─────────┘                              │
  │            │ miss or stale                          │
  │  ┌─────────▼─────────┐                              │
  │  │ Redis upstream    │ ← Layer 2: shared state       │
  │  │ cache (shared)    │   (millisecond reads)         │
  │  └───────────────────┘                              │
  └─────────────────────────────────────────────────────┘

INVALIDATION via Redis CLIENT TRACKING:
  Redis notifies subscribed clients when a key is invalidated
     ↓
  Client evicts from local in-memory cache automatically
     ↓
  Next read fetches fresh value from Redis (or origin)
  ✅ Invalidation is automatic, not manual
  ✅ Local cache stays consistent with upstream
  ✅ Eliminates the most common enterprise caching fear
```

Mateo highlights that **client tracking** — a Redis feature — is the key enabler. When a value is updated or invalidated in Redis, all subscribed processes are notified and evict their local copy. This makes the distributed cache enterprise-friendly because the invalidation problem is solved by the infrastructure, not by custom code.

---

## 6. Next.js Component and Page Caching

For SSR applications, caching can be applied at the component or page level — not just the HTTP response level. Next.js exposes hooks for plugging in a custom cache backend, which enables component-level granularity.

```
COMPONENT CACHE ARCHITECTURE (Next.js + Redis via Platformatic/Vite)

  Browser request
       ↓
  Next.js SSR request
       ↓
  ┌────────────────────────────────┐
  │  Component cache check         │
  │  key: route + data fingerprint │
  └─────────┬──────────────────────┘
            │ HIT → return cached HTML fragment
            │ MISS
            ↓
  React renders component
       ↓
  Output stored in Redis
       ↓
  Page assembled from fragments (some cached, some fresh)
       ↓
  Response served

✅ Cache personalized fragments independently from public fragments
✅ Partial invalidation — only re-render changed fragments
✅ Works across multiple Next.js instances sharing one Redis
❌ Requires shared Redis — adds infrastructure dependency
```

This is particularly powerful for pages that mix public and personalized content. Static headers, navigation, and product cards can be cached aggressively while the user's cart or recommendation section is always fresh. The Platformatic implementation surfaces this as a single Redis URL configuration.

---

## 7. HTTP Caching Standards — Don't Reinvent

Mateo and Luka make a strong point: the foundation for cache invalidation is already standardized. The main hesitation people have is around invalidation — but the answer exists and is already in production at scale.

```
EXISTING STANDARDS — Use These, Don't Reinvent

  HTTP Cache-Control headers   → expiry, freshness, revalidation
  ETags                        → conditional requests (If-None-Match)
  Surrogate-Control            → CDN-specific directives
  Cache Tags / Surrogate Keys  → Cloudflare's spec for tag-based
    (hashtags spec)              purging (invalidate all responses
                                 tagged "product-123" in one call)

✅ CORRECT:
  Use Cache-Control + ETags for HTTP response freshness
  Use Cloudflare surrogate keys for tag-based invalidation
  Use Redis client tracking for distributed in-process invalidation

❌ WRONG:
  Build a custom invalidation protocol
  Invent a new cache DSL instead of learning HTTP
  Use GraphQL or gRPC and then struggle to add caching
     (HTTP + JSON gives you caching primitives for free)
```

The `hashtags` spec from Cloudflare provides a practical, production-proven mechanism for purging groups of responses by tag, which covers the most common invalidation pattern without any custom infrastructure.

---

## 8. Relevance to Our Architecture

```
APPLICATION TO MODULAR MONOLITH (NestJS + Expo + Turborepo)

HTTP RESPONSE CACHING:
  ✅ Use standard Cache-Control headers on NestJS API responses
     for public or semi-public data (lookup data, categories, etc.)
  ✅ Use Redis (already in stack for BullMQ) as the shared cache store
  ✅ Apply client-side HTTP caching in fetch adapters (infrastructure layer)
  ❌ Don't implement custom expiry/invalidation logic —
     use Redis client tracking or Cloudflare surrogate keys

APPLICATION-LEVEL CACHING (Use Case Layer):
  ✅ Cache expensive external API responses at the infrastructure port level
     (e.g., InMemoryCache adapter wrapping a real HTTP adapter)
  ✅ Cache query results in InMemory fakes during testing —
     this is already the fake pattern, structurally correct
  ❌ Don't cache inside domain entities or use cases
     — caching is infrastructure, ports define the interface

TANSTACK QUERY (Frontend):
  ✅ TanStack Query IS the client-side cache for remote state
  ✅ staleTime controls how long data is considered fresh
  ✅ queryClient.invalidateQueries() is the invalidation primitive
  ❌ Don't duplicate server state in Zustand — let TanStack Query own it

REQUEST DEDUPLICATION:
  ✅ TanStack Query deduplicates concurrent requests for the same key
     automatically — no manual implementation needed
  ✅ For server-side deduplication (SSR, agentic calls), consider
     the async-cache-dedup pattern at the NestJS adapter layer

REDIS USAGE IN STACK:
  Redis is already present for BullMQ (task queues)
  ✅ Reuse the same Redis for component/HTTP caching
  ✅ Use Redis client tracking for distributed cache invalidation
     across multiple API instances
  ❌ Don't run a separate Memcached instance — Redis covers both
```

The agentic observation from the conversation is particularly relevant: as AI agents make high-frequency repeated calls to data sources, cache deduplication at the infrastructure layer becomes critical to prevent backend collapse. The same pattern applies to our use case layer when orchestrating multiple async operations.

---

## Summary

Caching is not one problem — it's a layered discipline from CDN edges down to in-process memory. Each layer addresses a different cost: network latency, compute, I/O. The fear around stale data and private data leakage is valid but resolvable through careful key design and the HTTP caching standards that already exist. The real risk isn't implementing caching — it's implementing it from scratch. Redis covers distributed state and invalidation via client tracking. HTTP Cache-Control and surrogate key specs cover response freshness and invalidation at the edge. TanStack Query covers client state on the frontend. None of these need to be reinvented. The only remaining work is understanding what to cache, where, and accepting that eventual consistency is a feature, not a bug.

[^1]: Mateo & Luka — [Caching Discussion: To Cache or Not to Cache](https://www.youtube.com/watch?v=tnidZ_9BH1w)
