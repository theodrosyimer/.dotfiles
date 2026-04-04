# 0007. Use Gateway and ACL Patterns for Inter-Module Communication

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — Gateway/ACL pattern validated in Booking→Listing cross-module communication

**Reevaluation triggers**: Module extraction to microservices (Gateway becomes HTTP API); team adopts an event mesh that makes synchronous Gateway calls unnecessary; more than 10 cross-module dependencies make the indirection cost unacceptable.

## Context

In a modular monolith ([ADR-0001](0001-use-modular-monolith-as-default-architecture.md)), modules need to communicate while maintaining model isolation. Each bounded context has its own ubiquitous language — "Booking" in the Booking context is a different model than how the Listing context references bookings.

Direct imports between modules create tight coupling and break encapsulation. If Module A imports Module B's domain entities, changes to B's internal model break A.

## Decision

**We will use the Gateway pattern (provider side) combined with the Anti-Corruption Layer pattern (consumer side) for all inter-module communication.**

Architecture:

```
Provider Module (Booking)              Consumer Module (Listing)
┌──────────────────────┐              ┌──────────────────────┐
│ domain/              │              │ domain/              │
│   BookingEntity      │              │   ports/             │
│                      │              │     IBookingPort     │ ← domain interface
│ contracts/           │              │                      │
│   BookingGateway ────┼──── DTOs ───→│ infrastructure/      │
│   dtos/              │              │   adapters/          │
│     BookingDTO       │              │     BookingACL ──────┤ implements IBookingPort
└──────────────────────┘              │       ↓ consumes     │
                                      │     BookingGateway   │
                                      └──────────────────────┘
```

Rules:

```
PROVIDER SIDE (Gateway):
  ✅ Exposes DTOs — never internal domain entities
  ✅ Maintains backward compatibility for consumers
  ✅ Lives in module's contracts/ directory

CONSUMER SIDE (ACL):
  ✅ Translates external DTOs to own domain model
  ✅ Implements domain port interface (not Gateway interface)
  ✅ Lives in consumer's infrastructure/adapters/ directory

DEPENDENCY FLOW:
  ✅ Use case → domain port (interface)      (clean dependency)
  ✅ ACL adapter → Gateway                    (infrastructure wiring)
  ✅ ACL adapter implements domain port        (adapter pattern)
  ❌ Use case → Gateway directly              (bypasses domain boundary)
  ❌ Use case → external module's domain/     (breaks encapsulation)
```

## Consequences

### Positive

- Model isolation — each context maintains its own domain model
- Language consistency — ubiquitous language stays within context boundaries
- Change isolation — internal model changes don't ripple across modules
- Testability — domain ports are easily faked in tests
- Migration readiness — Gateway can become HTTP API when extracting to microservice

### Negative

- More code — DTO, Gateway, ACL, and port interface per cross-module dependency
- Indirection — data flows through more layers than direct imports
- Must keep Gateway DTOs backward compatible (versioning discipline)

### Neutral

- ACL can apply domain-specific validation when translating DTOs

## Alternatives Considered

### Alternative 1: Direct Module Imports

Rejected because it creates tight coupling. Changing Module B's domain model breaks Module A at compile time — the exact problem bounded contexts are designed to prevent.

### Alternative 2: Shared Domain Events Only

Rejected as sole mechanism because some inter-module communication is synchronous query-based (e.g., "get space availability for this booking"). Events handle async side effects well but don't replace synchronous data needs.

## References

- Eric Evans: Domain-Driven Design — Anti-Corruption Layer pattern
- Project knowledge: Modular Monoliths — Gateway & ACL Patterns — see project `docs/explanation/architecture/modular-monoliths-gateway-acl.md`
- Related: [ADR-0001](0001-use-modular-monolith-as-default-architecture.md), [ADR-0004](0004-use-vertical-slice-architecture-within-modules.md)
