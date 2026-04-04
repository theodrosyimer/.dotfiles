# 0011. Use Task-Based API Design for CQRS Bounded Contexts

**Date**: 2026-03-02

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — task-based endpoints validated in Booking module; client-generated UUIDs proven for optimistic UI

**Reevaluation triggers**: Adoption of GraphQL for query surfaces making view-shaped REST endpoints redundant; projection proliferation exceeding 3 per entity suggesting a BFF layer is needed; team adopts a real-time protocol (WebSocket/SSE) that changes the command response model.

## Context

When a bounded context uses CQRS (as governed by [ADR-0009](0009-default-crud-escalate-to-cqrs.md)), the API layer must express commands and queries in a way that preserves business intent. Traditional CRUD-style REST endpoints (`PUT /resource/{id}` with a full entity body) destroy intent — the server cannot distinguish a price change from a status transition from a description edit, forcing conditional validation branches and coarse-grained authorization.

Greg Young identifies this as the "lost intent problem": a DTO representing current state after modification tells the server nothing about what the user actually did. Jimmy Bogard and Derek Comartin demonstrate that REST is fully compatible with CQRS when commands and projections are modeled as first-class HTTP resources rather than mapping entities to endpoints.

Additionally, returning view-shaped projections directly from query endpoints (without a BFF/gateway) is both simpler and faster than forcing entity-shaped responses that clients must reassemble. However, this means each query endpoint becomes a published contract requiring explicit versioning discipline.

This decision builds on [ADR-0009](0009-default-crud-escalate-to-cqrs.md) and applies within bounded contexts that have been identified as CQRS candidates.

## Decision

**We will use task-based command endpoints and view-shaped query endpoints for all CQRS bounded contexts, serving read model projections directly without a BFF layer.**

### Command endpoints

Commands are modeled as sub-resources expressing business intent:

```
COMMAND ENDPOINT PATTERN:
  ✅ POST /orders/place                    (PlaceOrderCommand)
  ✅ POST /orders/{id}/cancel              (CancelOrderCommand)
  ✅ POST /orders/{id}/ship                (ShipOrderCommand)
  ✅ PUT  /articles/{id}/publish           (idempotent command)

FORBIDDEN:
  ❌ PUT  /orders/{id}                     (generic update, intent lost)
  ❌ PATCH /orders/{id} { status: "x" }   (server must infer intent)
```

Command response conventions:

```
SYNC CREATION:
  POST /orders/place → 201 Created, Location: /orders/{id}
  Body: { status, createdAt }  (server-generated metadata only — client already has the ID)

ASYNC PROCESSING:
  POST /invoices/{id}/approve → 202 Accepted
  Location: /invoices/{id}/approval, Retry-After: 120

IDEMPOTENT STATE CHANGE:
  PUT /articles/{id}/publish → 200 OK or 204 No Content

NON-IDEMPOTENT ACTION:
  POST /orders/{id}/cancel → 200 OK with { status, cancelledAt }
```

ID generation: the client generates the UUID (v7) and includes it in the command payload. This follows Udi Dahan's guidance — the client already knows the ID before the server responds, enabling optimistic UI updates, eliminating the need for the command to return data, and making the command fully idempotent (resending the same command with the same ID is a no-op).

### Query endpoints

Each query endpoint returns a purpose-built, denormalized projection optimized for a specific view:

```
QUERY ENDPOINT PATTERN:
  ✅ GET /orders/{id}                → Order detail projection
  ✅ GET /orders/dashboard           → Dashboard stats projection
  ✅ GET /orders/{id}/tracking       → Tracking-specific projection
  ✅ GET /listings/search            → Search-optimized projection

FORBIDDEN:
  ❌ GET /orders/{id}?include=items,customer  (client assembles view)
  ❌ Reusing write model entities as query responses
```

### Read model contract discipline

Each API-facing read model is a published contract with its own Zod schema:

```
VERSIONING STRATEGY:
  ✅ Additive evolution: add new fields, never remove or rename existing ones
  ✅ Versioned endpoints (GET /v2/...) for breaking changes
  ✅ Separate projections per client type when shapes genuinely differ
  ❌ Conditional fields based on client type in a single projection
  ❌ Modifying response shape without schema versioning
```

### Multi-client views without BFF

When different clients need different shapes, create separate projections with separate query handlers and schemas rather than introducing a BFF:

```
MULTI-CLIENT APPROACH:
  ✅ ListingSearchWebProjection       (full context, nested objects)
  ✅ ListingSearchMobileProjection    (minimal flat payload)
  ✅ ListingSearchAdminProjection     (moderation + audit fields)

BFF ESCALATION — add a BFF only when:
  - Cross-service aggregation that no single projection covers
  - Client-specific protocol translation (WebSocket, SSE)
  - Multiple teams own services that projections span
```

## Consequences

### Positive

- Business intent preserved in every API call — focused validation, authorization, and audit per command
- Read performance optimized per view — each projection uses ideal storage and shape
- No BFF layer to maintain for the common case — simpler infrastructure
- Natural fit with HATEOAS — hypermedia links expose available commands based on state
- Concurrent write conflicts reduced — task-based commands touch only relevant fields
- Clear contract boundaries — Zod schemas define projection shapes explicitly

### Negative

- More endpoints than CRUD — each business action gets its own command endpoint
- Projection proliferation — different client views require separate query handlers
- Schema versioning overhead — read model contracts require explicit lifecycle management
- Eventual consistency visible to clients — read projections may lag behind commands (when using async projections)

### Neutral

- REST compatibility is preserved — commands as sub-resources are standard HTTP
- Existing tooling (OpenAPI/Swagger) works with task-based endpoints without modification
- Testing strategy unchanged — commands tested at use case boundary with fakes, projections tested as query handlers

## Alternatives Considered

### Alternative 1: BFF Layer for All View Shaping

A Backend-for-Frontend layer between clients and the API, responsible for assembling view-shaped responses from entity-based API responses.

Rejected because it adds an entire service layer, deployment, and latency for aggregation that CQRS read projections already solve natively. The BFF becomes a pass-through for most queries.

### Alternative 2: GraphQL as Universal Query Layer

Using GraphQL to let clients select exactly the fields they need from read models, eliminating the need for per-client projections.

Not rejected outright — remains a valid future option, especially if projection proliferation becomes unmanageable. Deferred because the current bounded contexts have well-defined, stable view requirements, and GraphQL introduces its own complexity (schema stitching, N+1 resolution, eventual consistency with mutations). Can be adopted incrementally for specific high-variability query surfaces.

### Alternative 3: CRUD REST with Smart Validation

Keep `PUT /resource/{id}` endpoints but add sophisticated server-side diffing to reconstruct intent from field changes.

Rejected because it's fragile (field-diffing breaks on concurrent edits), inverts responsibility (server guesses intent instead of client stating it), and produces unmaintainable validation code with conditional branches per field combination.

## References

- [Greg Young — Task-Based UI](https://cqrs.wordpress.com/documents/task-based-ui/)
- [Jimmy Bogard — CQRS and REST: the perfect match](https://lostechies.com/jimmybogard/2016/06/01/cqrs-and-rest-the-perfect-match/)
- [Derek Comartin — Is a REST API with CQRS Possible?](https://codeopinion.com/is-a-rest-api-with-cqrs-possible/)
- [Oskar Dudycz — Can command return a value?](https://event-driven.io/en/can_command_return_a_value/)
- [Lorenzo Nicora — REST-without-PUT](https://medium.com/@lorenzo.nicora/cqrs-and-rest-api-ed811a5c2fee)
- Project knowledge: CQRS API Design — Task-Based Commands with REST — see project `docs/explanation/event-sourcing/`
- Related: [ADR-0009](0009-default-crud-escalate-to-cqrs.md), [ADR-0004](0004-use-vertical-slice-architecture-within-modules.md), [ADR-0007](0007-use-gateway-and-acl-for-inter-module-communication.md)
