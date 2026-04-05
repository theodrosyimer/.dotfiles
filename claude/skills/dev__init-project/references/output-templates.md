# Output Templates

Concrete examples of generated files for different project patterns. Use these as starting points
— adapt to the user's specific choices, don't copy verbatim.

---

## Template A: Standard Stack (Modular Monolith + ES + NestJS + Expo)

### CLAUDE.md

```markdown
# {Project Name}

{One-line purpose}

## Communication

- Be concise — sacrifice grammar for conciseness
- Challenge ideas when planning — suggest alternatives, point out anti-patterns
- When asked questions, JUST ANSWER — don't modify code unless explicitly asked

## Project Structure

- Module structure: `!ls packages/modules/src/`
- Infrastructure subfolders group fakes alongside concrete siblings (e.g.,
  `infrastructure/repositories/` has both `drizzle-*.ts` and `*.fake.ts`)

output example of `!ls packages/modules/src/` for reference:
packages/modules/src/{module}/
├── contracts/ # Public API: gateway + dtos/
├── domain/ # entities/, value-objects/, commands/, events/, errors/, types/
│ # ES pure functions: decide.ts, evolve.ts, project.ts, react.ts
├── infrastructure/ # Concern-based subdirs, fakes alongside real impls
│ ├── event-store/
│ ├── repositories/
│ ├── mappers/ # toDomain/toPersistence pure functions
│ └── adapters/ # ACL implementations
├── slices/ # {feature}/ — handler, command, driver, fixture, test colocated
└── shared/ # (optional) module-internal

## Landmines

- NEVER barrel files (index.ts) except package top-level
- NEVER mocks — fakes by default, vi.fn() ONLY for React component callback props
- No getters on class props — use entity.props.x
- `type` by default — `interface` only for `implements`/`extends`
- `satisfies` over `: Type` for const declarations
- `#src/*` subpath imports in packages/modules, `@/*` tsconfig paths in leaf apps only
- `ApplicationException.cause` is internal — NEVER expose in HTTP responses

## Architecture

Modular monolith: modules = bounded contexts, vertical slices inside each.
Hexagonal: ports & adapters, DI via containers.
Gateway/ACL for inter-module communication.

### Error Architecture

`DomainError` (category: 'domain-rule') -> `ApplicationError` -> `ApplicationException`
(via static factories only). Domain returns Result (never throws); app layer unwraps ->
ApplicationException; NestJS maps -> HttpException. RFC 9457 ProblemDetails for HTTP status.

### Domain Modeling

- ADT / null-free: `_tag` discriminated unions for all states including absence
- ADTs stay in domain — boundaries use nullable fields or status enums
- Data Mapper: `toDomain`/`toPersistence` pure functions
- GDPR-by-design: PII out of event payloads

### Event Sourcing

Four pure functions: `decide` (command + state -> events), `evolve` (state + event -> state),
`project` (events -> read model), `react` (event -> side effects).
State-level dispatch: outer switch on `state._tag`, inner on `command._tag`/`event._tag`.

## Testing

TDD non-negotiable. Vitest only.

- Ultra-light fakes: public fields only, no behavior to prove
- Sociable unit tests at handler boundary with real domain services
- vi.fn() ONLY for React component callback props
- Each test wires own fakes in beforeEach — no shared container
- Fixtures: `createXxxFixture()` factories, `FailingStub` suffix, `ExpectedErrors` maps
- Tests colocated with code in slices/{feature}/
- 80/15/5: 80% handler, 15% component contract (RNTL), 5% integration/E2E

## Tech Stack

TypeScript v6, Node.js >=24, NestJS, Drizzle ORM + postgres, better-auth,
Vitest, Testing Library, Expo React Native, TanStack Query, UniWind,
Turborepo + pnpm, uuid v7, date-fns, native fetch, BullMQ, TanStack Form

**Observability:** Pino + OpenTelemetry + Sentry + Grafana. App speaks OTLP only.

**Never Use:** Jest, Axios, Prisma, Moment.js, NativeWind, npm/yarn, @nestjs/cqrs

## Vault References

Architecture deep-dives: `~/Dropbox/Notes/programming/architecture.md`
DDD patterns: `~/Dropbox/Notes/programming/ddd.md`
Event sourcing: `~/Dropbox/Notes/programming/event-sourcing.md`
Testing methodology: `~/Dropbox/Notes/programming/testing.md`
Error handling: `~/Dropbox/Notes/programming/error-handling.md`

## Skills

- `dev__plan-feature` — plan a feature with TDD test strategy
- `dev__tdd` — TDD RED-GREEN-REFACTOR cycle
- `dev__write-tests` — write tests for existing code
- `dev__refactor` / `dev__refactor-parallel` — safe refactoring
- `dev__conventional-commit` — conventional commits
- `arch__adr` — architecture decision records
- `arch__coupling-analysis` — evaluate coupling dimensions
```

### .claude/rules/module-boundaries.md

```markdown
Every module in `packages/modules/src/` is a bounded context.

- No direct imports across module boundaries — use gateway contracts only
- Inter-module calls go through gateway (contracts/) with ACL adapter (infrastructure/adapters/)
- Each module owns its data — no shared database tables
- Module public API = contracts/ folder only (gateway + DTOs)
```

### .claude/rules/event-sourcing-purity.md

```markdown
Event sourcing pure functions (`decide`, `evolve`, `project`, `react`) must be side-effect-free.

- `decide`: command + state -> events[] (no I/O, no randomness, no time)
- `evolve`: state + event -> new state (no I/O, deterministic)
- `project`: events -> read model updates (pure transformation)
- `react`: event -> side effect commands (the only place side effects originate)
- State-level dispatch: outer switch on `state._tag`, inner on command/event `_tag`
- IDs and timestamps come from ports (IdProvider, Clock), injected at handler level
```

### .claude/commands/new-module.md

```markdown
Scaffold a new module in the modular monolith.

Create the module structure at `packages/modules/src/$ARGUMENTS/`:

1. Read existing modules (`ls packages/modules/src/`) for conventions
2. Create directory structure:
   - `contracts/` — gateway interface + dtos/ folder
   - `domain/` — entities/, value-objects/, commands/, events/, errors/, types/
   - `infrastructure/` — repositories/, mappers/, adapters/
   - `slices/` — empty, ready for first feature
3. Create gateway interface in contracts/ with module name
4. Create initial domain types (entity, commands, events) with `_tag` discriminated unions
5. Create fake repository in infrastructure/repositories/
6. Register module in the NestJS module system

Module name from $ARGUMENTS should be kebab-case for folders, PascalCase for types.
```

### .claude/commands/new-slice.md

```markdown
Scaffold a new vertical slice (feature) in an existing module.

Usage: /new-slice {module-name}/{feature-name}

1. Parse $ARGUMENTS as `{module}/{feature}`
2. Create `packages/modules/src/{module}/slices/{feature}/` with:
   - `{feature}.command.ts` — command type with `_tag`
   - `{feature}.handler.ts` — command handler (the use case)
   - `{feature}.handler.spec.ts` — test file with fixture setup
   - `{feature}.fixture.ts` — `createXxxFixture()` factory
3. Wire handler to module's CQRS registration
4. Write first failing test (RED phase) based on simplest happy path
5. Follow existing slices in the module for conventions
```

---

## Template B: Simple CRUD (Monolith + NestJS + Drizzle)

### CLAUDE.md

```markdown
# {Project Name}

{One-line purpose}

## Communication

- Be concise — sacrifice grammar for conciseness
- Challenge ideas when planning — suggest alternatives
- When asked questions, JUST ANSWER

## Project Structure

src/
├── modules/ # Feature modules
│ └── {feature}/
│ ├── {feature}.controller.ts
│ ├── {feature}.service.ts
│ ├── {feature}.repository.ts
│ ├── {feature}.repository.fake.ts
│ ├── {feature}.dto.ts
│ ├── {feature}.entity.ts
│ └── {feature}.spec.ts
├── core/ # Shared infrastructure (DB, auth, config)
└── shared/ # Helpers, decorators, pipes


## Landmines

- NEVER barrel files except at package top-level
- NEVER mocks — fakes by default
- `type` by default — `interface` only for `implements`/`extends`
- Zod at API boundaries only — domain types are plain TypeScript

## Architecture

Simple modular monolith — NestJS modules as feature boundaries.
Repository pattern with Drizzle. Fakes alongside real implementations.
CRUD unless a module's complexity warrants CQRS (revisit when needed).

## Testing

TDD non-negotiable. Vitest only.
- Sociable tests through service layer with fake repositories
- Each test wires own fakes — no shared setup
- `createXxxFixture()` factories for test data

## Tech Stack

TypeScript v6, Node.js >=24, NestJS, Drizzle ORM + postgres,
Vitest, Testing Library, pnpm, uuid v7, date-fns, native fetch

**Never Use:** Jest, Axios, Prisma, Moment.js, npm/yarn

## Skills

- `dev__plan-feature` — plan features with TDD
- `dev__tdd` — TDD cycle
- `dev__conventional-commit` — conventional commits
```

---

## Template C: Frontend-Only (Expo)

### CLAUDE.md

```markdown
# {Project Name}

{One-line purpose}

## Communication

- Be concise — sacrifice grammar for conciseness
- Challenge ideas when planning — suggest alternatives
- When asked questions, JUST ANSWER

## Project Structure

app/ # Expo Router file-based routing
├── (tabs)/ # Tab navigation group
├── (auth)/ # Auth flow group
└── _layout.tsx # Root layout
src/
├── components/ # Shared UI components
├── features/ # Feature modules
│ └── {feature}/
│ ├── components/
│ ├── hooks/
│ ├── types.ts
│ └── {feature}.screen.tsx
├── hooks/ # Shared hooks
├── ports/ # Infrastructure interfaces
├── adapters/ # Port implementations (API clients, storage)
│ ├── real/
│ └── fakes/
└── theme/ # Design tokens, variants

## Landmines

- NEVER mocks — fakes for ports, vi.fn() ONLY for component callback props
- `type` by default — `interface` only for `implements`/`extends`
- UI is fully independent of backend — ports + fakes enable complete UI dev
- No `any` in shared code

## Architecture

Hexagonal frontend: UI components -> hooks -> ports -> adapters.
Ports define interfaces, fakes enable offline-first development.
TanStack Query for server state, context for app state.

## Testing

TDD non-negotiable. Vitest + RNTL.
- Component contract tests: `getByRole` as primary query
- Hook tests with fake adapters
- vi.fn() ONLY for onPress, onSubmit, onChange callbacks

## Tech Stack

TypeScript v6, Expo React Native, Expo Router, TanStack Query,
UniWind, TanStack Form, Vitest, Testing Library (RNTL), pnpm

**Never Use:** Jest, NativeWind, Axios, npm/yarn

## Skills

- `dev__react` — React/RN component patterns
- `ds__component-variant` — tailwind-variants components
- `dev__plan-feature` — plan features with TDD
- `dev__tdd` — TDD cycle
```

### .claude/commands/new-screen.md

```markdown
Scaffold a new screen in the Expo app.

Usage: /new-screen {feature-name}

1. Create `src/features/$ARGUMENTS/` with:
   - `$ARGUMENTS.screen.tsx` — screen component with layout
   - `components/` — feature-specific components
   - `hooks/use-$ARGUMENTS.ts` — feature hook (data fetching, state)
   - `types.ts` — feature types
2. Add route in `app/` directory following Expo Router conventions
3. Write component contract test with RNTL
4. Follow existing features for conventions
```

---

## Template D: Library / Package

### CLAUDE.md

```markdown
# {Project Name}

{One-line purpose}

## Communication

- Be concise
- When asked questions, JUST ANSWER

## Project Structure

src/
├── index.ts # Public API (only barrel file allowed)
├── {feature}.ts # Feature modules
└── {feature}.spec.ts

## Landmines

- Single barrel file at package root (index.ts) — no nested barrels
- No `any` — strict types throughout
- `type` by default — `interface` only for `implements`/`extends`

## Testing

TDD non-negotiable. Vitest only.

- Unit tests colocated with source
- Property-based tests for core algorithms where applicable

## Tech Stack

TypeScript v6, Vitest, pnpm

**Never Use:** Jest, npm/yarn
```
