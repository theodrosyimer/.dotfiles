# 0017. Extract Data Mapper as Standalone Concern

**Date**: 2026-03-18

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — Listing module mapper implemented and validated; pattern aligns with Fowler's original Data Mapper definition

**Reevaluation triggers**: Drizzle adds managed entity lifecycle (reflection-based hydration) making explicit mappers unnecessary; team adopts an ORM that handles domain mapping natively; mapper files proliferate beyond one per aggregate suggesting a code generation approach.

## Context

The repository pattern, as commonly implemented, bundles four separate concerns into one class: query orchestration (Drizzle calls), a generic CRUD interface, persistence-to-domain mapping (`toDomain`/`toPersistence`), and a test injection seam (the abstract port that fakes implement). Analysis of the pattern's critique literature (Jolicoeur, Fritzsche) and reflection on our own architecture revealed that these concerns have different lifecycles, different reasons to change, and different justifications for existing.

Martin Fowler's *Patterns of Enterprise Application Architecture* defines the Repository as a "collection-like interface" that sits *on top of* the Data Mapper layer. The Data Mapper is the pattern responsible for bidirectional translation between in-memory domain objects and database rows. The mapping was never the repository's job — the repository merely orchestrated calls to the mapper. In our codebase, `toDomain` and `toPersistence` logic was tangled inside repository adapter implementations, making the mapping invisible as an independent concern.

A second issue compounds this: TypeScript has no runtime reflection. Unlike C#/Java ORMs that hydrate entities via reflection (bypassing constructors), Drizzle ORM returns plain typed objects with no managed lifecycle. All domain mapping is necessarily explicit and manual in our stack. This makes the mapping code a significant, visible part of the infrastructure — it deserves its own home rather than being buried inside repository methods.

This decision builds on [ADR-0014](0014-keep-domain-layer-null-free-using-adt-read-models.md) (ADT return types for absence), [ADR-0016](0016-use-ultra-light-test-fakes-over-intelligent-inmemory.md) (ultra-light fakes), and [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md) (test at use case boundary).

Key forces:

- Drizzle returns plain objects (`InferSelectModel<typeof table>`) — explicit mapping to domain entities is unavoidable
- Domain entities use `Entity.reconstitute()` (inherited from base class) to hydrate from storage without re-running business validation — this is the mapper's primary call site
- The repository port exists as a test seam for sociable unit tests (ADR-0016), not as a persistence abstraction — its justification is testing, not "swapping databases"
- Test fakes don't need the mapper — they work with domain entities directly via the ADT (ADR-0014)
- The mapper is a pure function with zero dependencies — it should be independently locatable and testable

## Decision

**We will extract the Data Mapper from repository implementations into standalone pure function modules in `infrastructure/mappers/`, and explicitly document that the narrow repository port's justification is the test seam, not persistence abstraction.**

### Data Mapper structure

Each aggregate that needs persistence-to-domain translation gets a mapper module:

```
infrastructure/mappers/{entity}.mapper.ts

  toDomain(row: PersistenceRow) → DomainEntity
    Uses Entity.reconstitute() — bypasses business validation
    Handles type conversions (Drizzle numeric string → JS number, etc.)

  toPersistence(entity: DomainEntity) → PersistenceRow
    Reads from entity.props — the current (possibly mutated) state
    Handles reverse type conversions
```

The mapper is a `const` object with pure functions — no class, no state, no dependencies, no DI:

```ts
export const ListingMapper = {
  toDomain(row: ListingRow): ListingEntity {
    return ListingEntity.reconstitute({
      id: row.id,
      hostId: row.hostId,
      title: row.title,
      hourlyRate: Number(row.hourlyRate),
      isActive: row.isActive,
      createdAt: row.createdAt,
    })
  },

  toPersistence(entity: ListingEntity): Omit<ListingRow, 'updatedAt'> {
    return {
      id: entity.props.id,
      hostId: entity.props.hostId,
      title: entity.props.title,
      hourlyRate: String(entity.props.hourlyRate),
      isActive: entity.props.isActive,
      createdAt: entity.props.createdAt,
    }
  },
} as const
```

### What each piece is responsible for

```
UNBUNDLED RESPONSIBILITIES:

  infrastructure/mappers/{entity}.mapper.ts     ← Data Mapper (pure functions)
    Converts DB rows ↔ domain entities
    Calls Entity.reconstitute() for hydration
    Zero dependencies, survives if the repository changes

  domain/{entity}.repository.ts                 ← Test seam (narrow port)
    2-3 methods: findById, save (and occasionally findBy*)
    Returns ADT (ADR-0014): NoListing | ListingFound
    Abstract class for NestJS DI token
    EXISTS FOR: fake injection in sociable tests

  infrastructure/repositories/drizzle-*.ts      ← Adapter (uses mapper + port)
    Query orchestration (Drizzle calls)
    Calls mapper at the boundary
    Calls entity.commit() after successful write

  infrastructure/repositories/*-fake.ts         ← Ultra-light test fake
    Implements the port with public fields
    Does NOT use the mapper — works with domain entities directly
```

### Rules

```
DATA MAPPER RULES:

  ✅ One mapper per aggregate that has persistence
  ✅ Mapper lives in infrastructure/mappers/ (imports Drizzle types)
  ✅ Mapper uses Entity.reconstitute() — never Entity.create()
  ✅ Mapper is a const object with pure functions — no class, no DI
  ✅ Drizzle adapter calls the mapper at the boundary
  ❌ Mapper never lives in domain/ (it imports persistence schema types)
  ❌ Repository adapter never contains inline toDomain/toPersistence logic
  ❌ Test fakes never use the mapper (they work with domain entities directly)

PORT JUSTIFICATION:

  ✅ Port provides the test seam for sociable unit tests (80% bucket)
  ✅ Port methods express domain intent (findById, save)
  ✅ Port returns ADT for absence (ADR-0014)
  ❌ Port does NOT exist for "swapping databases"
  ❌ Port does NOT own mapping logic

PORT IS A PASSTHROUGH WHEN (watch for this):
  ⚠️ Every method is a 1-line Drizzle delegation with no composition
  ⚠️ Port method names mirror SQL operations (insert, select, update)
  ⚠️ Port accumulates query methods used by one slice each
```

### Entity reconstitution convention

The `Entity<T>` base class provides `reconstitute()` as an inherited static method. Child classes define `create()` with business validation. The mapper always calls `reconstitute()`, handlers always call `create()`:

```
ENTITY LIFECYCLE:

  create(input)        → child class, full business validation, for NEW entities
  reconstitute(data)   → inherited from Entity<T>, no validation, for STORAGE HYDRATION
```

## Consequences

### Positive

- Mapping logic is independently locatable — grep for `ListingMapper` instead of reading through repository methods
- Mapper survives regardless of repository changes — if the port is ever removed (going full vertical-slice), the mapper stays
- Pure functions are trivially testable if mapping gets complex (type conversions, nested structures)
- Clear separation of "what changes together" — mapper changes when schema or entity changes, port changes when domain queries change, adapter changes when Drizzle API changes
- `reconstitute()` on the base class eliminates the need for each entity to define its own hydration factory

### Negative

- One more file per aggregate (`{entity}.mapper.ts`) — small but real surface
- Developers must remember to put mapping in the mapper, not inline in the repository adapter
- The mapper imports both Drizzle schema types and domain entity types — it's a coupling point (but that coupling is inherent to any mapping solution)

### Neutral

- Event-sourced modules (Booking, Listing) don't need mappers for their event store — events are the persistence format, and the `evolve` function handles reconstitution. Mappers are relevant for CRUD modules and for read model projections that produce denormalized views
- The mapper pattern is compatible with future migration to a different ORM — only the mapper's import and type conversion logic changes

## Alternatives Considered

### Alternative 1: Keep mapping inside repository implementations

The status quo before this ADR. Rejected because the mapping logic is invisible — buried inside methods that also do query orchestration. When the Drizzle schema changes, you have to find every repository method that maps that field rather than updating one mapper function.

### Alternative 2: Remove the repository port entirely (full vertical slice)

Use the mapper directly in the handler, with Drizzle injected into the handler. Rejected because it eliminates the test seam for sociable unit tests at the use case boundary. Without a port to fake, the handler depends on Drizzle directly, and you can't fake Drizzle for the 80% test bucket. Testing entity logic in isolation (bypassing the handler) creates coupling to the entity's internal API.

### Alternative 3: ORM-level mapping (let Drizzle handle it)

Let the ORM map directly to domain entities. Rejected because Drizzle is SQL-first and returns plain typed objects — it has no managed entity concept, no reflection-based hydration, and no lifecycle hooks. All mapping is necessarily manual in our stack.

## References

- Martin Fowler: Data Mapper pattern — https://martinfowler.com/eaaCatalog/dataMapper.html
- Martin Fowler: Repository pattern — https://martinfowler.com/eaaCatalog/repository.html
- Khalil Stemmler: Implementing DTOs, Mappers & the Repository Pattern — https://khalilstemmler.com/articles/typescript-domain-driven-design/repository-dto-mapper/
- Derek Comartin: Should you use the Repository Pattern? With CQRS, Yes and No! — https://codeopinion.com/should-you-use-the-repository-pattern-with-cqrs-yes-and-no/
- Project knowledge: `repository-pattern-critique-and-alternatives.md`
- Project knowledge: The Repository Never Did the Mapping — see project `docs/explanation/architecture/`
- Related: [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md), [ADR-0014](0014-keep-domain-layer-null-free-using-adt-read-models.md), [ADR-0016](0016-use-ultra-light-test-fakes-over-intelligent-inmemory.md)
