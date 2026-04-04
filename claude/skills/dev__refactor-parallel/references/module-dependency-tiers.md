# Module Dependency Tiers for Safe Parallel Refactoring

This reference helps dev__refactor-parallel by defining module tier classification and dependency ordering rules that determine which modules can be safely refactored in parallel.

## Module = Bounded Context Implementation

In our modular monolith, each module implements a single bounded context. Modules are the physical code organization; bounded contexts are the strategic DDD concept.

```
packages/modules/src/
  booking/          # Module implementing Booking Bounded Context
  space-listing/    # Module implementing Listing Bounded Context
  payment/          # Module implementing Payment Bounded Context
  user/             # Module implementing Identity Bounded Context
```

## Tier Classification

### Tier 0: Core Subdomains
- Competitive advantage, highest business value
- Examples: Booking, Space Catalog
- **Rule**: ALWAYS use ACL when consuming from other modules
- **Rule**: NEVER conform to external systems
- **Rule**: NEVER shared kernel between core subdomains
- **Parallel refactoring**: Can refactor independently if ACL adapters are preserved

### Tier 1: Supporting Subdomains
- Necessary but not differentiating
- Examples: Payment Orchestration, User Profile
- **Rule**: Conformist acceptable for non-strategic integrations
- **Rule**: Customer-supplier relationship with core when they need data
- **Parallel refactoring**: Can refactor in parallel with core (different owners)

### Tier 2: Generic Subdomains
- Commodity functionality
- Examples: IAM, Notification
- **Rule**: Conformist to external providers acceptable
- **Rule**: Published language where standards exist (OAuth, push specs)
- **Parallel refactoring**: Safest to refactor -- fewest dependents

## Dependency Ordering for Refactoring

### Safe parallel refactoring
Two modules can be refactored in parallel when:
1. They have NO shared kernel
2. Communication is via Gateway (provider) + ACL (consumer)
3. Gateway DTOs remain stable during the refactoring
4. Each team owns its ACL adapter changes independently

### Unsafe parallel refactoring
Two modules CANNOT be safely refactored in parallel when:
1. They share a kernel (shared npm package, shared DB schema)
2. One conforms to the other (conformist -- changes ripple to domain core)
3. Gateway DTO contracts are being changed simultaneously

## Vertical Slices Within Modules

Each module uses vertical slices internally:
```
Module (Bounded Context)
  PlaceOrder/    (Vertical Slice)
  CancelOrder/   (Vertical Slice)
  UpdateOrder/   (Vertical Slice)
```

Slices within a module share the domain model but are independent features. Refactoring one slice does not affect others unless the shared domain entity changes.

## Cross-Module Communication Boundaries

```
Provider Module                Consumer Module
  contracts/                     infrastructure/adapters/
    Gateway (stable DTOs)  --->    ACL Adapter (translates to domain model)
```

**During refactoring, preserve**:
- Gateway interface and DTO shapes (provider side)
- Domain interface the ACL implements (consumer side)

**Can change freely**:
- Internal domain model within either module
- ACL translation logic (as long as domain interface contract holds)
- Feature/slice internals
