## Implementation Sequence (per story)

1. **Define slice** — Gherkin acceptance criteria → prd.json specification
2. **Define fixtures** as inter-agent contracts
3. **Write failing acceptance test** from prd.json (RED)
4. **TDD inner loop** (RED → GREEN → REFACTOR):
   - Domain types, entities, value objects (plain TypeScript — type-driven modeling)
   - Handlers orchestrating domain logic with injected ports
   - Zod schemas at boundaries only, where needed
5. **MICRO-COMMIT**
6. **Build UI** with fakes (commands) and stubs (queries returning fixtures)
   - Components are UI execution boxes — hooks are the glue layer
   - Component tests (RNTL) verify UI contracts only
7. **MICRO-COMMIT**
8. **Wire backend** — replace fakes with real adapters
9. **MICRO-COMMIT**
10. **Refactor** domain model if valuable

### Story Ordering (from PRD):
1. CORE use cases first (entities/schemas emerge via TDD)
2. EDGE cases after primary CORE is working
3. UI is independent of backend — ports + fakes enable full UI development without any real adapters
4. INTEGRATION stories (real adapters) can happen in parallel or after UI
5. For CROSS_CONTEXT: implement depended-upon context first

---

## Architecture Decisions

- **PRD Complexity Mapping**: CRUD → transaction script (with narrow ports for testability), CQRS → full domain, CROSS_CONTEXT → full domain + Gateway/ACL/events
- **Type-Driven + Zod at Boundaries**: Domain types are plain `type` aliases. Zod at boundaries only. See `.claude/rules/type-driven-zod-boundaries.md`
- **Entity Methods**: Add business behavior methods from domain modeling (MANDATORY)
- **Component Responsibility**: Components only handle UI, hooks bridge to business logic
- **Testing Focus**: Test business behavior through handlers, test UI contracts through components
- **Cross-Context**: Provider exposes Gateway with DTOs, consumer uses ACL implementing domain port

## Implementation Quality

- **Abstract Classes for Ports**: Use abstract classes for infrastructure ports (repositories, external services, providers)
- **Fake-First for Ports**: Create ultra-light fakes for infrastructure ports before real implementations
- **No Fakes for Domain Services**: Domain services are pure logic - inject real instances
- **Business Rules in Entities**: Single-entity rules ALWAYS in entities (MANDATORY)
- **Business Rules in Domain Services**: Multi-entity coordination in stateless domain services
- **Handler Orchestration**: Handlers coordinate but contain NO business logic
- **Integration Testing**: Test real adapters directly against real infrastructure (testcontainers)

## Common Mistakes to Avoid

- **No Business Logic in Components**: ALL domain logic goes through entities/services, orchestrated by handlers
- **No Business Logic in Handlers**: Handlers orchestrate only - delegate to entities and domain services
- **No Infrastructure in Domain Services**: Domain services are PURE - no repos, no APIs, no I/O
- **No Fakes for Domain Services**: Domain services don't need fakes - they're pure business logic
- **No Mocks Ever**: NEVER use `vi.fn()` / `jest.fn()`. Fakes for commands, stubs for queries, spies on real impls only
- **No Floating Literals**: NEVER use inline literal objects in tests — use `createXxxFixture()` factory functions
- **No Duplicate Fixtures**: Fixtures are created ONCE and reused everywhere — query stubs, tests, UI dev
- **No Premature CQRS**: Start simple, evolve complexity only when business demands it
- **No Skipping Entities**: Single-entity business rules are MANDATORY in entities
- **No Anemic Entities**: Entities must have behavior, not just data
- **No Direct Gateway Usage**: Handlers depend on domain ports, ACL implements them
- **No Barrel Files**: NEVER use index.ts except at package top-level in monorepo

---

## Quick Reference Checklist

### When Creating New Business Logic, Ask:

**For ENTITIES:**
- [ ] Does this operate on a single entity's data?
- [ ] Is this about state management or transitions?
- [ ] Is this an internal consistency check?
- [ ] Does this NOT need external context?

**For DOMAIN SERVICES:**
- [ ] Does this need data from multiple entities?
- [ ] Is this a complex calculation across entities?
- [ ] Does this coordinate entity operations?
- [ ] Is this pure business logic (no infrastructure)?

**For HANDLERS:**
- [ ] Does this orchestrate a complete workflow?
- [ ] Does this involve database operations?
- [ ] Does this call external APIs?
- [ ] Is this an acceptance criterion from a user story?

### Quick Reference

**Domain Architecture Decision (Two-Question Test):**
```
Q1: Operates on SINGLE entity's data? Q2: Needs EXTERNAL info?
YES Q1, NO Q2 → Entity | NO Q1 OR YES Q2 → Domain Service | Infrastructure? → Handler
```

**Testing Strategy:**
Business Behavior (Handlers - 80%) > Component Contracts (15%) > Integration/E2E (5%)

**Test Doubles:**
Command handlers → ultra-light fakes (*Fake) | Query handlers → stubs (return fixtures) | Spies on real impls only | NEVER mocks/vi.fn()

**Test Data:**
`createXxxFixture()` factory functions — NEVER floating literal objects in tests

**Layer Responsibilities:**
- Entities: Own data, single-entity rules, state transitions
- Domain Services: Stateless, multi-entity coordination, pure logic (NO infrastructure)
- Handlers: Orchestration, infrastructure coordination, transaction boundaries (NO business logic)

**Cross-Context Pattern:**
- Provider: Gateway in `contracts/` returns DTOs
- Consumer: Domain port in `domain/ports/`, ACL in `infrastructure/adapters/`
- Handler depends on domain port, NEVER on Gateway directly
