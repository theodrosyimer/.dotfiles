# 0004. Use Vertical Slice Architecture Within Modules

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — validated through Booking and Listing module implementations

**Reevaluation triggers**: A slice grows to require its own sub-slices (nested vertical slices); a shared concern spans 5+ slices and feels wrong in `domain/`; team requests a different internal organization.

## Context

Within each module (bounded context), code needs an internal organization strategy. Traditional layered architecture (controllers → services → repositories) creates horizontal coupling — adding a feature requires touching every layer, and layers tend to accumulate shared abstractions that increase coupling over time.

Features within a module are largely independent of each other. A "create booking" feature shares domain entities with "cancel booking" but has different validation, different side effects, and different API contracts. Organizing by technical layer obscures this natural feature independence.

Key forces:
- Features within a module should be independently developable
- Minimize coupling between features while maximizing cohesion within a feature
- Support parallel agent/developer work on different features
- Must coexist with shared domain logic (entities, value objects) used across features

## Decision

**We will organize code within modules as vertical slices, where each feature is a self-contained slice cutting through all architectural layers.**

Module structure:

```
packages/modules/src/{module-name}/
  domain/                       # Shared domain model within this bounded context
    types/                      # Domain types, read models (ADTs)
    entities/                   # Domain entities with business logic
    value-objects/              # Value objects
    commands/                   # Domain command types
    events/                     # Domain events
    errors/                     # Domain errors
    decide.ts                   # Pure function (ES modules)
    evolve.ts                   # Pure function (ES modules)
    project.ts                  # Pure function (ES modules)

  slices/                       # Vertical slices (one per use case)
    request-booking/
      request-booking.handler.ts     # Use case implementation
      request-booking.command.ts     # Command class with static from(dto) ACL
      request-booking.driver.ts      # Test driver
      request-booking.handler.test.ts
      request-booking-dto.fixture.ts

  infrastructure/               # Adapters for this module
    event-store/                # Event persistence (fakes alongside real)
    repositories/               # Entity persistence (fakes alongside real)
    mappers/                    # Data Mapper pure functions
    adapters/                   # ACL implementations for cross-module integration

  contracts/                    # Public Gateway for other modules
    {module}-gateway.ts
    dtos/
```

Key principles:
- **Slice = Vertical Slice = Use Case**: Each slice directory contains everything specific to that use case
- **Shared domain is separate**: Entities, value objects, and types used by multiple slices live in `domain/`
- **Tests co-locate**: Each slice's tests live alongside its implementation
- **No cross-slice imports**: Slices within the same module do not import from each other directly

```
WITHIN A MODULE:
  ✅ Slice → own module's domain/          (shared entities, types)
  ✅ Slice → own module's contracts/       (for internal routing)
  ❌ Slice A → Slice B                     (slices are independent)
  ❌ Slice → other module's internals      (use Gateway + ACL via infrastructure/)
```

## Consequences

### Positive

- Adding a feature means adding a directory, not modifying shared layers
- Features can be developed in parallel by different agents/developers
- Deleting a feature is trivial — remove the directory
- Natural alignment with user stories (one story ≈ one slice)
- Test isolation — each feature's tests are self-contained

### Negative

- Some duplication between slices (e.g., similar validation patterns) — acceptable trade-off
- Shared domain logic requires careful thought about what belongs in `domain/` vs inside a slice
- Naming conventions matter more (consistent slice directory naming)

### Neutral

- `slices/` was chosen over `features/` because a slice is a vertical cut through all architectural layers (handler, command, test, fixture), while "feature" implies a user-facing capability that may span multiple slices

## Alternatives Considered

### Alternative 1: Traditional Layered Architecture

Rejected because horizontal layers (controllers/, services/, repositories/) create artificial coupling. Every feature change touches multiple layers, and shared service classes accumulate unrelated methods.

### Alternative 2: Feature Modules (Fully Self-Contained)

Rejected because fully self-contained features duplicate domain entities. Shared domain logic (BookingEntity with business rules) must exist in one place and be referenced by multiple features.

## References

- Jimmy Bogard: "Vertical Slice Architecture" — https://www.jimmybogard.com/vertical-slice-architecture/
- Kamil Grzybek: "I see vertical slices in hierarchical form" — modular-monolith-with-ddd Discussion #225
- Project knowledge: Vertical Slice vs Modular Monolith — see project `docs/explanation/architecture/vertical-slice-vs-modular-monolith.md`
- Related: [ADR-0001](0001-use-modular-monolith-as-default-architecture.md)
