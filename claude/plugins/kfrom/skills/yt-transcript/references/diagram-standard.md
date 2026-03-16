# Diagram & Architecture Visualization Standard

<!-- 
PURPOSE: Define how to create diagrams and architecture visualizations in this project.
AUDIENCE: LLM agents (Claude Code, Cursor, etc.) generating documentation or architectural context.
RULE: ALL diagrams in this project MUST follow this standard. No exceptions.
-->

## Why Not Mermaid?

Mermaid is a visual notation designed for human rendering in browsers. It has critical limitations for LLM workflows:

- **LLMs don't render** — they parse text. A Mermaid `FEAT_A --> DOM_A` arrow carries no intent, no constraint, no rationale.
- **Readability degrades fast** — beyond 6-8 nodes, Mermaid diagrams become unreadable even for humans.
- **No enforceability** — a Mermaid diagram can't express "this path is FORBIDDEN because it violates module encapsulation."
- **Redundant context** — LLMs process structured text faster and more accurately than parsing diagram syntax.

**Exception**: Mermaid is acceptable ONLY for simple flowcharts (< 6 nodes, linear flow) embedded in user-facing README files. Never use Mermaid for architecture rules, dependency maps, or decision frameworks.

## The Standard: Structured Text Diagrams

All diagrams in this project use **structured text with explicit rules**. This format combines:

- **WHAT** — the structure (directories, layers, components)
- **HOW** — the allowed dependency paths
- **WHY NOT** — the forbidden paths with rationale

---

## Format Rules

### 1. Use ASCII Box Diagrams for Structure

```
┌─────────────────────────────────────────┐
│              Module: Booking            │
├─────────────────────────────────────────┤
│  api/            Public Gateway + DTOs  │
│  features/       Use cases (slices)     │
│  infrastructure/ Adapters, fakes, repos │
│  domain/         Schemas, entities      │
└─────────────────────────────────────────┘
```

### 2. Use Arrow Notation for Dependencies

```
DEPENDENCY DIRECTION (top = outer, bottom = inner):

  app → api → features → domain
                            ↑
                     infrastructure

  Read as: "app depends on api, api depends on features, etc."
  Infrastructure points UP to domain (implements ports).
```

### 3. Use ✅/❌ for Rules and Constraints

This is the most critical format element. Every dependency rule, design decision, or architectural constraint MUST use ✅/❌ markers.

```
INTER-MODULE COMMUNICATION:
  ✅ Module A features/ → Module B api/            (via Gateway DTOs)
  ❌ Module A features/ → Module B domain/          (breaks encapsulation)
  ❌ Module A features/ → Module B features/        (creates coupling)
  ❌ Module A features/ → Module B infrastructure/  (leaks implementation)
```

### 4. Use Indented Hierarchy for Layer Details

```
MODULE STRUCTURE: packages/modules/{name}/
  domain/         → Pure business logic. DEPENDS ON: shared only.
  features/       → Vertical slices. DEPENDS ON: own domain, other modules' api/ ONLY.
  infrastructure/ → Adapters. DEPENDS ON: own domain, own features.
  api/            → Public contract. DEPENDS ON: own module layers only.
```

### 5. Use Tables for Comparisons and Decisions

```
APPROACH         | WHEN TO USE                    | TRADE-OFF
Simple CRUD      | Basic data ops, lookup tables  | No domain protection
CQRS             | Complex workflows, events      | More code, more structure
Domain Service   | Multi-entity business rules    | Coordination overhead
```

---

## Diagram Templates

### Template: Layer Dependency Map

```
LAYER DEPENDENCIES — {Context Name}

  {Layer A}  → {Layer B}  → {Layer C}
                               ↑
                          {Layer D}

ALLOWED:
  ✅ {Layer A} → {Layer B}   ({reason})
  ✅ {Layer D} → {Layer C}   ({reason})

FORBIDDEN:
  ❌ {Layer C} → {Layer A}   ({reason — e.g. "domain must stay framework-agnostic"})
  ❌ {Layer A} → {Layer D}   ({reason — e.g. "app should not bypass public API"})
```

### Template: Module Communication Map

```
INTER-MODULE RULES — {Project Name}

  Module A ──[ api/ Gateway ]──▶ Module B
  Module B ──[ api/ Gateway ]──▶ Module A

ALLOWED PATHS:
  ✅ {Module} features/ → other module api/     (DTOs only, via Gateway)
  ✅ {Module} features/ → shared/               (base utilities)

FORBIDDEN PATHS:
  ❌ {Module} features/ → other module domain/         ({rationale})
  ❌ {Module} features/ → other module features/       ({rationale})
  ❌ {Module} features/ → other module infrastructure/ ({rationale})
  ❌ shared/ → any module                              ({rationale})
```

### Template: Data Flow

```
DATA FLOW — {Feature Name}

  1. User submits form
     ↓
  2. Component calls hook (useCreateBooking)
     ↓
  3. Hook delegates to UseCase.execute(input)
     ↓
  4. UseCase validates via Schema.parse()
     ↓
  5. UseCase applies Entity business rules
     ↓
  6. UseCase persists via Repository port
     ↓
  7. Hook invalidates query cache
     ↓
  8. UI re-renders with new state
```

### Template: Decision Matrix

```
DECISION — {What are we deciding?}

CONTEXT: {Brief situation description}

OPTION A: {Name}
  ✅ {Pro}
  ✅ {Pro}
  ❌ {Con}

OPTION B: {Name}
  ✅ {Pro}
  ❌ {Con}
  ❌ {Con}

CHOSEN: {Option} — because {one-sentence rationale}.
```

### Template: Good/Bad Pattern

```
PATTERN — {Pattern Name}

❌ BAD — {Why this is wrong}:
  {code snippet or structural example showing the anti-pattern}

✅ GOOD — {Why this is correct}:
  {code snippet or structural example showing the correct approach}

RULE: {One-sentence enforceable rule}
```

---

## Complete Example: Project Architecture

```
ARCHITECTURE — Modular Monolith (Turborepo)

MONOREPO STRUCTURE:
  apps/
    front/             Expo app (mobile + web)
    api/               NestJS backend
    admin/             Admin dashboard
  packages/
    modules/{name}/    Bounded context implementations
    modules/shared/    Cross-module base utilities

MODULE STRUCTURE: packages/modules/{name}/
  domain/         → Pure business logic. DEPENDS ON: shared only.
  features/       → Use cases (vertical slices). DEPENDS ON: own domain, own features, other modules' api/ ONLY.
  infrastructure/ → Adapters (repos, fakes). DEPENDS ON: own domain, own features.
  api/            → Public Gateway + DTOs. DEPENDS ON: own module layers only.

DEPENDENCY DIRECTION:
  app → module api/ → features/ → domain/
                                     ↑
                              infrastructure/

  shared/ → NOTHING (base utilities: Entity, Executable, DomainException)

INTER-MODULE COMMUNICATION:
  ✅ features/ → other module api/             (Gateway returns DTOs, never entities)
  ❌ features/ → other module domain/          (breaks bounded context encapsulation)
  ❌ features/ → other module features/        (creates hidden coupling between slices)
  ❌ features/ → other module infrastructure/  (leaks adapter implementation details)
  ❌ domain/   → features/                     (inner layer must not know outer layer)
  ❌ domain/   → infrastructure/               (domain defines ports, never implementations)
  ❌ shared/   → any module                    (shared is a leaf dependency, never imports modules)

DOMAIN LAYER FRAMEWORK ISOLATION:
  ❌ domain/ imports from: react, react-native, expo-*, @tanstack/*, @nestjs/*, drizzle-orm, pg
  ✅ domain/ imports from: zod (boundary schemas only), shared/ (base classes)

TESTING BOUNDARIES:
  ✅ Test files (*.test.ts) may import fakes from own module infrastructure/
  ✅ Test files may import from any layer within own module
  ❌ Test files must not import other modules' internals (use api/ Gateway stubs)
```

---

## Enforcement Checklist

When creating any diagram or architectural visualization in this project:

  ✅ Use structured text, not Mermaid (unless simple README flowchart < 6 nodes)
  ✅ Include ✅/❌ markers for every rule and constraint
  ✅ State WHAT is allowed AND what is forbidden (both sides)
  ✅ Add rationale in parentheses for forbidden paths
  ✅ Use consistent arrow notation: → for dependencies, ↑ for inverse dependencies
  ✅ Use ASCII boxes for structural outlines
  ✅ Use indented hierarchy for directory/layer breakdowns
  ✅ Keep each diagram self-contained (readable without external context)
  ❌ Do not use Mermaid for architecture rules or dependency maps
  ❌ Do not create diagrams without explicit allowed/forbidden rules
  ❌ Do not omit rationale — every ❌ must explain WHY
