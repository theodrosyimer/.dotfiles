# 0014. Keep Domain Layer Null-Free Using ADT Read Models

**Date**: 2026-03-13

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — pattern proven across Booking (project function) and Listing (repository
port) modules; boundary translation rules validated through Gateway, HTTP, and frontend analysis

**Reevaluation triggers**: TypeScript adds native pattern matching that makes `T | null` as
ergonomic as ADT dispatch; a third-party library (e.g., Effect) becomes the project standard and
provides a superior Option type; team feedback consistently reports ADT boilerplate as a friction
point.

## Context

The `project` function (read-side fold, parallel to `evolve`) must represent the absence of a
booking — i.e. when the event stream for a given `bookingId` is empty. The naive solution is
`BookingDetailReadModel | null`, returning `null` when no events exist.

This decision builds on [ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md),
which establishes that domain functions (`decide`, `evolve`, `project`) use discriminated union ADTs
with exhaustive `_tag`-based dispatch. It also builds on
[ADR-0003](0003-use-fakes-over-mocks-for-testing.md) and
[ADR-0005](0005-test-business-behavior-at-use-case-boundary.md), which establish that domain logic
must be pure, deterministic, and testable without infrastructure.

Key forces:

- `evolve` already models absence as `InitialBookingState = { _tag: 'InitialBookingState' }` —
  returning `null` from `project` would be inconsistent with the established write-side pattern
- `null` conflates two semantically distinct facts: "the event stream is empty" (a domain fact) and
  "no record was found" (an infrastructure/query fact) — using `null` for both blurs a meaningful
  boundary
- Tony Hoare coined `null` as his "billion-dollar mistake" (1965/2009): in untyped languages, null
  defeats the type system entirely; in TypeScript with `strictNullChecks`, it is safer but still
  loses semantic information
- Martin Fowler's Special Case pattern recommends returning a typed object that implements the
  expected interface rather than a bare `null`
- Every future `project` function added to any module faces the same question — the decision must be
  documented as a cross-cutting convention, not left to per-module discretion
- The same reasoning applies to repository port return types: the port is defined in `domain/` —
  it's a domain-level abstraction, and `findById` returning `T | undefined` forces every consumer to
  do a truthiness check that loses the explicitness of the domain's vocabulary

## Decision

**We will keep the domain layer entirely null-free by representing absence as a named ADT variant,
and translate that variant to `null` exactly once at the API boundary.**

### ADT applicability

The pattern applies to **all domain-level queries that can return absence**:

```
ADT APPLICABILITY:
  ✅ project function read models (NoBooking / BookingDetail)
  ✅ Repository port return types (NoListing / ListingFound)
  ✅ Any domain-level query that models presence/absence

NAMING CONVENTION:
  project read models:  No<Entity>      / <Entity>Detail
  repository results:   No<Entity>      / <Entity>Found
```

### Read-side ADT convention

Every `project` function uses a dedicated read model ADT following this shape:

```
READ MODEL ADT STRUCTURE:
  type <Entity>ReadModel =
    | { _tag: 'No<Entity>' }          ← absence variant (mirrors InitialBookingState)
    | { _tag: '<Entity>Detail'; ... }  ← presence variant (the actual read model)

  const INITIAL_<ENTITY>_READ_MODEL: <Entity>ReadModel = { _tag: 'No<Entity>' }
```

Example for Booking:

```ts
type BookingReadModel =
  | { _tag: 'NoBooking' }
  | { _tag: 'BookingDetail'; bookingId: string; status: ...; ... }

const INITIAL_BOOKING_READ_MODEL: BookingReadModel = { _tag: 'NoBooking' }
```

### Repository port ADT convention

Example for a CRUD module repository port:

```ts
// domain/types/listing-read-model.ts
type NoListing = { readonly _tag: 'NoListing' }
type ListingFound = { readonly _tag: 'ListingFound'; readonly listing: ListingEntity }
export type FindListingResult = NoListing | ListingFound

export const noListing = { _tag: 'NoListing' } as const satisfies NoListing
export const listingFound = (listing: ListingEntity) =>
  ({ _tag: 'ListingFound', listing }) as const satisfies ListingFound

// domain/listing.repository.ts (port)
export abstract class ListingRepository {
  abstract findById(id: string): Promise<FindListingResult>
  abstract save(listing: ListingEntity): Promise<void>
}
```

The handler uses an if/else early return (not switch/case) for two-variant ADTs:

```ts
const result = await this.listings.findById(listingId)

if (result._tag === 'NoListing') {
  throw new ApplicationException({ message: 'Listing not found', status: 404 })
}

// TypeScript narrows to ListingFound — result.listing is type-safe
result.listing.deactivate()
await this.listings.save(result.listing)
```

Ultra-light test fakes (ADR-0016) default to the absence variant:

```ts
export class ListingRepositoryFake implements ListingRepository {
  findByIdResult: FindListingResult = noListing
  savedListing: ListingEntity | undefined = undefined
  // ...
}
```

### Null boundary rule

The principle is **"translate domain absence into a boundary-appropriate representation at every
boundary."** The domain ADT is strictly internal to the producing module — it never crosses any
boundary. Each boundary owns its own representation of absence.

**Why ADTs must not cross boundaries:** A `_tag`-based ADT is a domain modeling artifact — it
encodes how the producing module internally represents state. Exposing it in Gateway DTOs or API
responses couples consumers to the producer's internal vocabulary. Renaming `NoBooking` to
`BookingAbsent` or splitting it into `BookingNotFound | BookingExpired` becomes a breaking contract
change instead of an internal refactor. Consumers should depend on stable contract representations
(nullable fields, status enums, HTTP status codes), not on the producer's evolving domain language.

```
BOUNDARY TRANSLATION TABLE:

  Boundary              Absence representation       Rationale
  ─────────────────     ────────────────────────     ─────────────────────────────
  Domain layer          ADT (NoBooking, NoListing)   Semantic, exhaustive, null-free
  Repository port       ADT (FindListingResult)      Port is domain-level abstraction
  Gateway DTO           nullable field or status      Consumers don't import domain ADTs
  HTTP response         null / 404 + RFC 9457        REST convention, universal
  Frontend (Expo/web)   Frontend-owned types          UI owns its representation
```

```
DOMAIN LAYER (decide, evolve, project, domain types):
  ✅ Use ADT absence variants (NoBooking, InitialBookingState, NoListing)
  ✅ Return types are always non-nullable
  ❌ Never return null or undefined
  ❌ Never accept null as a parameter

GATEWAY BOUNDARY (contracts/ → inter-module DTOs):
  ✅ Translate absence variant → nullable DTO or status enum at the Gateway method level
  ✅ The Gateway's return type uses contract vocabulary, not the domain ADT
  ✅ Consuming module's ACL translates Gateway DTO into its own domain representation
  ❌ Never expose _tag-based ADTs in Gateway DTOs — they are domain internals
  ❌ Never import a module's domain/ types from another module's contracts/

HTTP BOUNDARY (query handler execute() → API response):
  ✅ Translate absence variant → null exactly once, explicitly, with a comment
  ✅ Keep the translation in the query handler's execute() method — not in project()
  ✅ Task-based query endpoints (ADR-0011) return view-shaped DTOs — nullable when absent
  ❌ Never leak the absence variant (_tag: 'NoBooking') into the API response
  ❌ Never use const { _tag, ...rest } = readModel to strip the tag — use explicit field mapping

FRONTEND BOUNDARY (monorepo shared types):
  ✅ Share Zod schemas for API wire format (the contract both sides agree on)
  ✅ Frontend defines its own UI types/ADTs if exhaustive matching helps component logic
  ✅ Frontend data layer (TanStack Query hooks) maps API response → UI representation
  ❌ Never import backend domain types (NoBooking, BookingReadModel) into frontend packages
  ❌ Monorepo package proximity is not an excuse to bypass boundary discipline
```

### Concrete boundary translation pattern

```ts
// GetBookingDetailQueryHandler.execute()
const readModel = events.reduce(bookingProject, INITIAL_BOOKING_READ_MODEL)

// Translate domain absence → API null at the boundary (deliberate, localized — see ADR-0014)
if (readModel._tag === 'NoBooking') return null

// Explicit field mapping: BookingDetail (domain) → BookingDetailReadModel (transfer type)
return {
  bookingId: readModel.bookingId,
  guestId: readModel.guestId,
  spaceId: readModel.spaceId,
  status: readModel.status,
  period: readModel.period,
  price: readModel.price,
}
```

### Entity reconstitution convention

When hydrating domain entities from database rows (via a Data Mapper), the entity must be created
without re-running business validation — the data was already validated at creation time. The
`Entity<T>` base class provides a static `reconstitute()` method inherited by all subclasses:

```
ENTITY LIFECYCLE — Two Entry Points

  NEW ENTITY (use case / handler):
    ListingEntity.create(input)
      → child class validates business rules
      → calls new ListingEntity(validated props)
      → base constructor: spread + freeze initialState

  RECONSTITUTED ENTITY (Data Mapper / storage hydration):
    ListingEntity.reconstitute(data)
      → inherited from Entity<T> base class
      → calls new ListingEntity(trusted props)
      → base constructor: spread + freeze initialState
      → NO business validation — data was validated at creation time
```

`reconstitute()` lives on the base class so every entity inherits it — child classes only define
`create()`. Mappers always call `reconstitute()`, handlers and use cases always call `create()`.

## Consequences

### Positive

- Full structural consistency between write-side (`evolve` / `InitialBookingState`) and read-side
  (`project` / `NoBooking`) — zero cognitive overhead when switching between the two
- Absence is semantically named — `NoBooking` is a domain concept; `null` is a JavaScript primitive
  with no meaning
- Future discrimination is trivially extensible — `NoBooking` can later become
  `BookingNotFound | BookingArchived` without changing the query handler's contract
- No nullable types anywhere in the domain layer — `strictNullChecks` pressure removed from pure
  functions entirely
- Exhaustive `_tag`-based dispatch works uniformly across both absence and presence variants
- Repository ports express domain vocabulary — `FindListingResult` is richer than
  `ListingEntity | undefined`
- `reconstitute()` on the base class eliminates the need for each entity to define its own hydration
  factory
- Domain ADT vocabulary can evolve freely (rename, split, merge variants) without breaking any
  consumer — Gateway DTOs, API responses, and frontend types are decoupled
- Frontend owns its UI types — can model absence however best fits component logic without backend
  dependency

### Negative

- One extra type per module (`No<Entity>`) — small but real maintenance surface
- Query handlers must contain the explicit `_tag === 'No<Entity>'` guard and field mapping —
  slightly more code than `return readModel` with a nullable type
- Gateway methods must translate domain ADTs to nullable DTOs — one additional mapping per
  cross-module query
- Monorepo makes it trivially easy to import domain types across packages — discipline required to
  resist the shortcut
- New contributors unfamiliar with the pattern may initially reach for `T | null` — ADR must be
  referenced in code review

### Neutral

- The API response type (`BookingDetailReadModel | null`) is unchanged — only the internal domain
  representation changes; consumers see no difference
- `projectScenario` in the test DSL uses `.thenReadModel('NoBooking')` instead of
  `.thenReadModel(rm => expect(rm).toBeNull())` — a parallel improvement in test expressiveness

## Alternatives Considered

### Alternative 1: `T | null` in `project` (nullable return type)

Return `BookingDetailReadModel | null` directly from `bookingProject`. TypeScript `strictNullChecks`
ensures the caller handles the null branch.

Rejected because it breaks structural consistency with `evolve` (which never returns `null`),
conflates "stream empty" with "not found" at the type level, and loses semantic information that may
be needed for future discrimination. It also leaks a JavaScript primitive into the domain layer
where an ADT is more appropriate.

### Alternative 2: `Option<T>` / Maybe monad (fp-ts / Effect)

Wrap absence in a functional container: `Option<BookingDetailReadModel>`. Forces explicit handling
via `map`, `flatMap`, `getOrElse`.

Rejected because it introduces a heavy functional programming dependency (`fp-ts` or `effect`) for a
problem already solved by discriminated unions — the codebase's existing idiom. Interop with
non-monadic code becomes verbose. The ADT approach achieves the same type safety with no new
dependencies and no style shift.

### Alternative 3: Throw on empty stream

Throw a domain exception if `getEvents()` returns an empty array in the query handler.

Rejected because "no booking found" is a normal, expected query outcome — not an exceptional
condition. Using exceptions for control flow violates the project's error boundary convention
([ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md)) and makes query handlers
harder to test.

### Alternative 4: Propagate domain ADTs across module and API boundaries

Return `_tag`-based ADTs in Gateway DTOs and/or HTTP responses so consumers can pattern-match on
`NoBooking` directly. In a monorepo, import the domain ADT type from the producing module's package.

Rejected because it couples every consumer — other modules, HTTP clients, frontend apps — to the
producing module's internal domain vocabulary. Renaming or splitting an ADT variant becomes a
breaking change across all boundaries. REST clients don't have a TypeScript compiler enforcing
exhaustive `switch` on `_tag` — they'd check string values manually, which is a worse, non-standard
version of checking `null` or reading a 404. Task-based query DTOs
([ADR-0011](0011-use-task-based-api-design-for-cqrs-bounded-contexts.md)) already shape data for the
screen — the screen either has data or it doesn't, making nullable sufficient at the API boundary.

## References

- Tony Hoare: "Null References: The Billion Dollar Mistake" —
  https://www.infoq.com/presentations/Null-References-The-Billion-Dollar-Mistake-Tony-Hoare/
- Martin Fowler: Special Case pattern — https://martinfowler.com/eaaCatalog/specialCase.html
- Related: [ADR-0003](0003-use-fakes-over-mocks-for-testing.md)
- Related: [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md)
- Related: [ADR-0007](0007-use-gateway-and-acl-for-inter-module-communication.md)
- Related: [ADR-0011](0011-use-task-based-api-design-for-cqrs-bounded-contexts.md)
- Related: [ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md)
- Related: [ADR-0013](0013-adopt-nullables-selectively-for-infrastructure-gateways.md)
- Related: [ADR-0017](0017-extract-data-mapper-as-standalone-concern.md)
