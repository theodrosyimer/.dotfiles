## Core Architecture

### The Three Layers

```
┌─────────────────────────────────────────┐
│   Handlers (Application Layer)          │ ← Acceptance tests here
│   - Orchestration                        │
│   - Infrastructure coordination          │
│   - Transaction boundaries               │
└─────────────────────────────────────────┘
              ↓ uses
┌─────────────────────────────────────────┐
│   Domain Services (Domain Layer)         │
│   - Pure business logic                  │
│   - Cross-entity operations              │
│   - Complex calculations                 │
└─────────────────────────────────────────┘
              ↓ operates on
┌─────────────────────────────────────────┐
│   Entities (Domain Layer)                │
│   - State management                     │
│   - Single-entity business rules         │
└─────────────────────────────────────────┘
```

### The Golden Rule

> **"Entities own their data and state. Domain Services coordinate entities and handle cross-cutting business logic. Handlers orchestrate workflows and manage infrastructure."**

### Layer Responsibilities

**Entities (Domain Layer)**
- Own their data and internal state
- Contain business rules for a SINGLE entity
- Manage state transitions (e.g., `booking.confirm()`)
- Validate their own internal consistency
- Expose behavior, not just data

**Domain Services (Domain Layer)**
- Coordinate MULTIPLE entities
- Pure business logic (NO infrastructure)
- Stateless operations
- Complex calculations across entities
- Domain-specific validation

**Handlers (Application Layer)**
- Orchestrate complete business workflows
- Manage infrastructure (database, APIs, email)
- Define transaction boundaries
- Primary testing boundary (acceptance tests)
- Thin orchestration layer

| Layer | Responsibility | Infrastructure | Fakes Needed |
|-------|---------------|----------------|--------------|
| **Entity** | Single-entity rules, state transitions | None | No |
| **Domain Service** | Multi-entity coordination, complex calculations | None | No |
| **Handler** | Orchestration, workflow, transactions | Yes (via ports) | Yes (for ports) |

---

## Quick Decision Framework

### Two-Question Test

```
Question 1: Does this logic operate on a SINGLE entity's data?
Question 2: Does this logic need information from OUTSIDE the entity?

YES to Q1, NO to Q2 → ENTITY METHOD
NO to Q1 OR YES to Q2 → DOMAIN SERVICE

Does it involve infrastructure (database, API, email)? → HANDLER
```

### Visual Decision Tree

```
            START: Where should this logic go?
                          ↓
            ┌─────────────────────────────┐
            │ Does it involve             │
            │ infrastructure?             │
            │ (DB, API, Email, File I/O)  │
            └─────────────────────────────┘
                      ↓ YES
            ┌─────────────────────────────┐
            │      HANDLER               │
            │  (Application Layer)        │
            └─────────────────────────────┘
                      ↓ NO
            ┌─────────────────────────────┐
            │ Does it use data from       │
            │ multiple entities?          │
            └─────────────────────────────┘
                      ↓ YES
            ┌─────────────────────────────┐
            │   DOMAIN SERVICE            │
            │   (Domain Layer)            │
            └─────────────────────────────┘
                      ↓ NO
            ┌─────────────────────────────┐
            │ Does it operate on a        │
            │ single entity's data?       │
            └─────────────────────────────┘
                      ↓ YES
            ┌─────────────────────────────┐
            │      ENTITY                 │
            │   (Domain Layer)            │
            └─────────────────────────────┘
```
