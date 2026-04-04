# Context Dependency Map for Refactoring Order

This reference helps dev__refactor-parallel by defining context relationship types and how they determine safe refactoring dependency order.

## The Nine Context Mapping Patterns

### Patterns by Coupling Strength (strongest to weakest)

| Pattern | Coupling | Refactoring Impact |
|---------|----------|-------------------|
| Shared Kernel (SK) | Highest | CANNOT refactor either side independently |
| Partnership | High | Must coordinate refactoring jointly |
| Conformist (CF) | High | Upstream changes ripple to downstream domain core |
| Customer-Supplier (CS) | Medium | Downstream has some influence on upstream planning |
| Open Host Service (OHS) | Low | Provider publishes, consumers adapt independently |
| Anti-Corruption Layer (ACL) | Low | Consumer manages transformation independently |
| Published Language (PL) | Lowest | Standard exists, teams translate independently |
| Separate Ways | None | No technical coordination needed |

### Big Ball of Mud
- Warning sign, not a relationship pattern
- NEVER conform to it, NEVER share kernel with it
- ALWAYS use ACL against it

## Three Team Dependency Types

**Mutually Dependent**: Team A changes force Team B to adapt AND vice versa
- Patterns: Shared Kernel, Partnership
- Refactoring: Must happen together -- NEVER in parallel

**Upstream/Downstream**: Upstream changes force downstream to adapt (not vice versa)
- Patterns: Customer-Supplier, Conformist, OHS+ACL
- Refactoring: Upstream first, downstream adapts after

**Free**: Changes in either direction don't affect the other
- Patterns: Published Language, Separate Ways
- Refactoring: Fully parallel, no coordination

## Refactoring Order Decision Matrix

### Can refactor in parallel?

| Relationship | Parallel? | Condition |
|-------------|-----------|-----------|
| SK (Shared Kernel) | NO | Must refactor together |
| Partnership | NO | Must coordinate jointly |
| CF (Conformist) | RISKY | Only if upstream contracts frozen |
| CS (Customer-Supplier) | YES | If upstream API stable |
| OHS + ACL | YES | Gateway DTOs stable |
| PL (Published Language) | YES | Standard doesn't change |
| Separate Ways | YES | No dependency |

### Recommended refactoring sequence
1. Break shared kernels first (highest risk)
2. Replace conformist relationships with ACLs
3. Stabilize Gateway DTOs (OHS contracts)
4. Parallel refactoring of independent modules

## Model Propagation Danger

The most insidious risk: **conformist chains**.

```
Module A --[CF]--> Module B --[SK]--> Module C

Change in C propagates through B into A silently.
Bugs appear in A, nobody knows why.
```

**Before refactoring, map these chains and break them**:
- Replace shared kernels with Gateway+ACL
- Replace conformist relationships with ACL adapters
- Each ACL stops model propagation at the adapter ring

## Application to Our Modular Monolith

```
Core Subdomains (Booking, Space Catalog):
  ALWAYS ACL when consuming from other modules
  NEVER conform to external systems
  NEVER shared kernel between core subdomains

Supporting Subdomains (Payment, User Profile):
  Conformist acceptable for non-strategic integrations
  Customer-supplier with core when they need data changes

Generic Subdomains (IAM, Notification):
  Conformist to external providers acceptable
  Published language where standards exist
```

## Communication Bandwidth Mapping

High bandwidth (high coordination cost):
- Shared Kernel, Customer-Supplier, Partnership, Conformist

Low bandwidth (low coordination cost):
- OHS, Published Language, ACL, Separate Ways

**Refactoring goal**: Move relationships from high to low bandwidth before attempting parallel work.

## Sources

- Michael Plod, "Introduction to Context Mapping" (DDD Europe 2022)
- Eric Evans, "Domain-Driven Design" (2003), Chapter 14
