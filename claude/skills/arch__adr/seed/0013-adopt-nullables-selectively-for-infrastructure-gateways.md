# 0013. Adopt Shore's Nullable Pattern Selectively for Infrastructure Gateways

**Date**: 2026-03-13

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: medium — pattern is well-reasoned but no real gateway implementation exists yet to validate it

**Reevaluation triggers**: First real ACL gateway adapter is implemented (validates or invalidates the pattern); team finds `createNull()` on production classes uncomfortable for code review; Output Tracking proves less useful than expected compared to read-back assertions.

## Context

The project uses a fake-driven testing strategy ([ADR-0003](0003-use-fakes-over-mocks-for-testing.md)): `InMemory*` repository classes and `*FailingStub` classes implement the same port interfaces as their real counterparts, enabling sociable unit tests at the use case boundary with no external dependencies.

James Shore's **Nullable pattern** (*Testing Without Mocks*, 2018–2023) offers an alternative: instead of a separate in-memory class, the real infrastructure class exposes a `createNull()` static factory that disables external communication while retaining normal internal behaviour. Two companion patterns accompany it:

- **Configurable Responses** — pre-configure what the Nullable returns at construction time, replacing imperative in-memory state seeding
- **Output Tracking** — observe what the infrastructure class sent outward, replacing read-back assertions on an in-memory store

The question is whether to adopt this pattern wholesale, selectively, or not at all, given the existing architecture and current codebase state.

> ⚠️ Shore's "Nullable" has nothing to do with `null` values or TypeScript nullable types. The name is unfortunate in a `strictNullChecks` codebase. The pattern is about infrastructure objects with an "off switch", not about absent values.

Key forces:
- Real Drizzle/Postgres implementations do not exist yet — only in-memory fakes
- ACL gateway adapters (`SpaceListingAdapter`, future `PaymentGatewayAdapter`) make real network calls and have no meaningful in-memory equivalent
- `*FailingStub` classes are explicit, named, and co-located with their ports — valued for discoverability
- Domain pure functions (`decide`, `evolve`, `project`) are side-effect free and need no infrastructure testing strategy

## Decision

**We will adopt Shore's Nullable pattern selectively: for infrastructure gateway adapters only, not for event stores or repositories, and not before a real implementation exists.**

```
APPLY NULLABLES TO:
  ✅ ACL gateway adapters (SpaceListingAdapter, PaymentGatewayAdapter, NotificationGatewayAdapter)
     — these make real network calls; no meaningful in-memory equivalent exists
  ✅ Any infrastructure wrapper with external I/O where Output Tracking adds value
     (asserting what was sent, not what was stored)

DO NOT APPLY NULLABLES TO:
  ❌ Event stores and repositories — keep as dedicated fake classes (*Fake suffix per ADR-0016)
  ❌ *FailingStub classes — keep as explicit named classes; more discoverable than
     Configurable Response parameters
  ❌ Domain pure functions (decide, evolve, project) — side-effect free, no strategy needed
  ❌ Any class without a real production implementation yet — createNull() before the real
     class exists adds complexity with no payoff
```

When a gateway implements `createNull()`, it must:

```
NULLABLE GATEWAY CONTRACT:
  ✅ Returns an instance of the same class (not a subclass or separate type)
  ✅ Accepts a Configurable Responses parameter for pre-seeding return values
  ✅ Exposes a track*() Output Tracking method for side-effect assertions
  ✅ Fully functional in every respect except the external I/O
  ❌ Must not require a separate *Fake class alongside it
```

## Consequences

### Positive

- Eliminates drift between real and fake for gateway adapters — `createNull()` lives on the real class; structural changes to the gateway cannot silently break a separate fake
- Output Tracking is more precise than read-back assertions — asserting on what was *sent* rather than what was *stored* is a meaningful distinction for write-side infrastructure
- Fewer files per gateway — no separate `*Fake` adapter class; `SpaceListingAdapter.createNull()` replaces it
- Configurable Responses are cleaner for gateway query tests — pre-configuring return values at construction avoids imperative state seeding

### Negative

- Mixes test infrastructure into production classes — `createNull()` is test-facing code living in a production file; introduces tension with the current clean separation enforced by co-locating fakes in `infrastructure/` subfolders
- Naming confusion in TypeScript — "Nullable" collides with the established meaning of nullable types in `strictNullChecks` codebases; must be explained to new contributors
- Configurable Responses are less discoverable than `*FailingStub` — named stub classes with `ExpectedErrors` maps are self-documenting; Configurable Response parameters require reading the `createNull()` signature to understand available failure modes
- No immediate payoff until real implementations exist — applying the pattern prematurely adds complexity without value

### Neutral

- Sociable tests at the use case boundary remain unchanged in structure; only the test double construction mechanism changes for gateway-level tests
- `*Fake` (ADR-0016) and `*FailingStub` naming conventions are used for repositories and event stores — Nullables introduce a parallel convention for gateways only

## Alternatives Considered

### Alternative 1: Adopt Nullables Wholesale

Replace all `*Fake` and `*FailingStub` classes with `createNull()` factories on every infrastructure class.

Rejected because `BookingEventStoreFake` is the primary test infrastructure for the booking module and warrants its own dedicated file. `*FailingStub` classes with `ExpectedErrors` maps are more explicit and discoverable than Configurable Response parameters. Wholesale adoption would also require retrofitting every existing infrastructure class before real implementations exist, yielding complexity without immediate value.

### Alternative 2: Do Not Adopt Nullables

Keep the current strategy of separate `*Fake` and `*FailingStub` classes for all infrastructure.

Rejected because the drift risk between a real gateway implementation and a separate fake grows over time. Output Tracking is genuinely superior to read-back assertions for write-side infrastructure. For ACL gateway adapters in particular, `createNull()` is the right abstraction — a full `SpaceListingAdapterFake` would be over-engineering with no domain state to maintain.

## References

- James Shore: Testing Without Mocks — https://www.jamesshore.com/v2/blog/2018/testing-without-mocks
- James Shore: A Light Introduction to Nullables — https://www.jamesshore.com/v2/projects/nullables
- Martin Fowler: Special Case pattern — https://martinfowler.com/eaaCatalog/specialCase.html
- Related: [ADR-0003](0003-use-fakes-over-mocks-for-testing.md)
- Related: [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md)
- Related: [ADR-0007](0007-use-gateway-and-acl-for-inter-module-communication.md)
