# 0001. Use Modular Monolith as Default Architecture

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — validated through 6+ modules implemented with clear boundaries

**Reevaluation triggers**: Need for independent deployment of a specific module; team grows beyond 8 engineers requiring autonomous service ownership; latency requirements that in-process communication cannot meet.

## Context

The project needed an architectural pattern that balances domain isolation with development simplicity. Starting with microservices introduces distributed system complexity (network failures, eventual consistency, deployment orchestration) before the domain boundaries are even well-understood. Starting with an unstructured monolith risks creating a big ball of mud that's expensive to untangle later.

The team is small, and development velocity matters more than independent deployment at this stage. However, the architecture must support a clear migration path to microservices if and when independent scaling or deployment becomes necessary.

Key forces:
- Small team, rapid iteration needed
- Domain boundaries still being discovered through frontend-first development
- Need strong module isolation without distributed system overhead
- Must support future microservices extraction without rewrite

## Decision

**We will use a modular monolith as the default starting architecture.**

Each module represents a bounded context with strict boundaries:

```
packages/modules/src/{name}/
  contracts/      → Public API: gateway + dtos/. DEPENDS ON: own module layers only.
  domain/         → Pure business logic. DEPENDS ON: core/ only.
  slices/         → Vertical slices. DEPENDS ON: own domain, other modules' contracts/ ONLY.
  infrastructure/ → Adapters. DEPENDS ON: own domain, own slices.
```

Infrastructure uses concern-based subdirectories:

```
infrastructure/
  event-store/    → Event persistence (ES modules): fakes alongside real impls
  repositories/   → Entity persistence (CRUD modules): fakes alongside real impls
  mappers/        → Data Mapper pure functions (toDomain/toPersistence)
  adapters/       → ACL implementations for cross-module integration
```

The monorepo package structure distinguishes load-bearing primitives from convenience utilities:

```
CORE VS SHARED — Litmus test

  src/core/       → Deleting it breaks EVERY module (load-bearing primitives)
    entity.ts, executable.ts, result.ts
    clock/        → port + adapters colocated (clock.ts, fixed-clock.ts, system-clock.ts)
    event-store/  → port definition (event-store.ts)
    id-provider/  → port definition (id-provider.ts)
    errors/       → application-exception.ts, problem-details.*
    types/        → instant.ts

  src/shared/     → Deleting it breaks only consumers (convenience utilities)
    helpers/      → string.ts, utility-types.ts
    infrastructure/observability/
    tests/        → test-dsl.ts
```

Inter-module communication rules:

```
ALLOWED:
  ✅ Module A slices/ → Module B contracts/       (via Gateway DTOs)
  ✅ Module A infrastructure/ → Module A domain/   (implements ports)

FORBIDDEN:
  ❌ Module A slices/ → Module B domain/          (breaks encapsulation)
  ❌ Module A slices/ → Module B slices/          (creates coupling)
  ❌ Module A slices/ → Module B infrastructure/  (leaks implementation)
  ❌ shared/ → any module                           (shared must stay generic)
```

Modules communicate through Gateway + Anti-Corruption Layer (ACL) patterns. Gateways expose DTOs, never internal domain entities. ACL adapters in the consumer's infrastructure layer translate DTOs to the consumer's domain model.

Architectural fitness is enforced via `eslint-plugin-boundaries` and ArchUnitTS fitness tests.

## Consequences

### Positive

- Single deployment unit — no distributed system complexity
- In-process communication — microsecond latency, atomic transactions when needed
- Strong module boundaries prepare for microservices extraction
- Teams can own entire modules while sharing a single codebase
- Vertical slices within modules enable independent feature development

### Negative

- All modules must be deployed together (no independent scaling yet)
- A bug in one module can theoretically crash the entire process
- Requires discipline to maintain module boundaries (hence fitness tests)
- Shared database means modules can't have fully independent data stores

### Neutral

- In-process event bus replaces network-based messaging (simpler but less independently scalable)

## Alternatives Considered

### Alternative 1: Microservices from Day One

Rejected because domain boundaries aren't yet well-understood. Premature service splitting leads to distributed monolith — the worst of both worlds. Migration path from modular monolith to microservices is well-documented and lower risk.

### Alternative 2: Unstructured Monolith

Rejected because without explicit module boundaries, coupling grows silently. Extracting services later from an unstructured monolith is significantly harder than from a modular one.

## References

- Sam Newman: "Most companies would do better with a modular monolith than with microservices"
- Kamil Grzybek: modular-monolith-with-ddd (GitHub)
- Project knowledge: Udi Dahan Decoupling Approach in Modular Monoliths — see project `docs/explanation/architecture/udi-dahan-decoupling-modular-monoliths.md`
- Related: [ADR-0002](0002-type-driven-domain-modeling-with-zod-at-boundaries.md), [ADR-0004](0004-use-vertical-slice-architecture-within-modules.md)
- Related: [ADR-0018](0018-separate-core-primitives-from-shared-utilities.md)
