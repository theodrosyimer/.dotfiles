# CLAUDE.md

Constraint and routing document. Detailed patterns live in skills and docs. Read
the relevant skill BEFORE writing code. Violating these constraints causes
expensive rework.

## Communication

- Be extremely concise — sacrifice grammar for conciseness
- Challenge ideas when planning — suggest alternatives, point out anti-patterns,
  correct misconceptions
- When asked questions, JUST ANSWER — don't modify code unless explicitly asked
- Markdown footnotes ([^1], [^2]) with source URLs when creating documents with
  citations
- If you don't know, say so — never fabricate
- Verify uncertain technical claims before presenting as fact
- Include version context for technology-specific answers

## Dotfiles & Skills

- **Claude in my Dotfiles:** `~/.dotfiles/claude/`
- **My Plugins:** `~/.dotfiles/claude/plugins/`
- **My Skills:** `~/.dotfiles/claude/skills/`
- **My Hooks:** `~/.dotfiles/claude/hooks/`

## Code Constraints

- `type` for data shapes — `interface` only for `implements` or `extends` (never
  `&`; `extends` has significantly better TS perf)
- `satisfies` over `: Type` for const declarations — preserves literal types
  (`_tag` fields)
- `substring` over `slice` for string utilities
- `exactOptionalPropertyTypes: true` — fix:
  `...(field !== undefined && { field })`
- No barrel files (index.ts re-exports) except at monorepo package top-level
- No getters on class props — getters for computed/derived values only; use
  `entity.props.x`
- No `any` in shared packages
- Concise variable names — long name = scope too big, refactor
- `rg`/`fd` over `grep`/`find` for file-searching (not for pipe operations)
- All code comments in English

### Type-Driven Domain Modeling + Zod at Boundaries

- Domain commands, events, entities: plain `type` aliases with discriminated
  unions (`_tag`), no Zod
- Zod at boundaries only: API inputs, inter-module contracts, external data (DB,
  third-party, env)
- Always `z.infer<typeof Schema>` — never duplicate types alongside a Zod schema
- Structural validation (format, shape) → boundary schemas; business rules →
  entities/domain services

## Module Structure

```
packages/modules/src/{module}/
├── contracts/       # Public API: gateway + dtos/
├── domain/          # entities/, value-objects/, commands/, events/, errors/, types/, schemas/
│                    # ES modules: decide.ts, evolve.ts, project.ts, react.ts at domain root
├── infrastructure/  # Concern-based subdirs, fakes alongside real impls
│   ├── event-store/
│   ├── repositories/
│   ├── mappers/         # toDomain/toPersistence pure functions
│   └── adapters/        # ACL implementations
├── slices/          # {feature}/ — handler, command, driver, fixture, test colocated
└── shared/          # (optional) module-internal
```

### Core vs Shared

- `src/core/` — deleting breaks every module (entity.ts, executable.ts,
  result.ts, clock/, event-store/, id-provider/, errors/, types/). Ports +
  adapters colocated per concern.
- `src/shared/` — deleting breaks only consumers (helpers/,
  infrastructure/observability/, tests/).
- `src/architecture/` — arch tests.

## Architecture

- Modular monolith: modules = bounded contexts, vertical slices inside each
- Hexagonal: ports & adapters, DI via containers
- Gateway/ACL for inter-module communication — ACL adapters in
  `infrastructure/adapters/`
- IDs generated in frontend (optimistic UI, natural command idempotency)
- Frontend-first: UI drives data discovery, infrastructure decisions come last
- Framework-agnostic domain layer — switching UI framework rewrites only UI
  layer
- Trunk-based development, branch by abstraction, dark launches, feature flags,
  rollback-capable releases
- SDD: Gherkin acceptance criteria + `prd.json` as starting point; TDD
  RED-GREEN-REFACTOR drives implementation

### Error Architecture

`DomainError` (code, `category: 'domain-rule'`, metadata) → `ApplicationError`
(code, category union, metadata, no `httpStatus`) → `ApplicationException` (via
`fromDomainError()` / `fromApplicationError()` static factories only). `Error`
suffix for domain, `Exception` suffix for application. Domain layer returns
`Result` (never throws); application layer unwraps → `ApplicationException`;
NestJS maps → `HttpException`. RFC 9457 `ProblemDetails` factory is single
source of truth for HTTP status codes.

### Domain Modeling

- ADT / null-free domain: `_tag` discriminated unions for all states including
  absence (`NoBooking`, `NoListing`)
- ADTs stay in domain layer — gateway DTOs, API boundaries, frontend use
  nullable fields or status enums
- Repositories handle persistence↔domain conversion via Data Mapper pure
  functions (`toDomain`/`toPersistence`)
- GDPR-by-design: PII out of event payloads from day one. Forgettable Payloads
  for user profiles, Crypto Shredding for transactional contexts

### Event Sourcing & CQRS

- ES-by-default for core subdomains (high replay value); CRUD for generic/simple
  supporting
- Replay value determines ES adoption — near-zero → CRUD; concrete (GDPR audit,
  customer support, cross-context debugging) → ES
- Four pure functions: `decide` (command + state → events), `evolve` (state +
  event → new state), `project` (events → read model), `react` (event → side
  effects)
- State-level dispatch: outer switch on `state._tag`, inner switch on
  `command._tag` or `event._tag`
- Start CRUD, evolve to CQRS when business complexity demands it (CRUD / CQRS /
  CROSS_CONTEXT classification)

## Testing

TDD non-negotiable. Every production line responds to a failing test.

- **Vitest only** — never Jest
- **Ultra-light test fakes** — nearly inert: public fields only
  (`events: BookEvent[] = []`, `appendedEvents`, `appendCalledWithStreamId`). No
  internal Map, no filtering logic, no `clear()`/`getAll()`. No behavior to
  prove → no contract tests needed
- **Demo fakes are separate** — `InMemory` prefix, Map-based, frontend DI only,
  never in tests. Test doubles use `Fake` suffix
- **Sociable unit tests** at use case boundary with real domain services — fake
  only infrastructure ports
- **`vi.fn()` ONLY for React component callback props** (onSubmit, onPress,
  onChange). No mocks ever; fakes by default, spies on real impls only
- **No shared test container** — each test wires own fakes in `beforeEach`
- **Fixtures are contracts**: `createXxxFixture()` factories, no floating
  literals. `FailingStub` always suffixed. `ExpectedErrors` maps co-located with
  port
- **Fakes alongside concrete siblings** — `infrastructure/repositories/` holds
  both `drizzle-*.ts` and `in-memory-*.ts`
- **80/15/5** — 80% handler tests, 15% component contract tests (RNTL,
  `getByRole` primary query), 5% integration/E2E
- **ArchUnitTS** in Vitest — LCOM96b: domain < 0.5, infrastructure < 0.7, shared
  < 0.4

## Tech Stack

- Node.js ≥24, TypeScript strict mode, NestJS
- Drizzle ORM + postgres driver (never Prisma)
- better-auth (@better-auth/expo)
- Vitest, Testing Library, supertest, testcontainers
- Expo React Native (mobile + web), TanStack Query, UniWind (never NativeWind),
  Tailwind v4
- Turborepo + pnpm (never npm/yarn)
- uuid v7, date-fns (migrate to Temporal when stable), native fetch (never
  Axios)
- BullMQ for async jobs
- React Hook Form (considering TanStack Form migration)
- Swagger for API docs

### Observability

- Pino (nestjs-pino) + OpenTelemetry + Sentry + Grafana stack
- `PinoInstrumentation` for log-trace correlation (auto-injects traceId/spanId)
- `BatchSpanProcessor` for async trace export
- Pino log redaction for PII
- Sentry via `pino-sentry-transport` worker thread — never
  `Sentry.captureException()` on main thread
- R.E.D metrics derived from spans by OTel Collector `spanmetrics` connector —
  no app-side Prometheus client, no manual metrics recording
- Prometheus scraped from OTel Collector, Grafana dashboards + alerting, Grafana
  Tempo for trace storage
- App only speaks OTLP — backend choice is infrastructure config

## Never Use

Jest, Axios, Prisma, Moment.js, NativeWind, npm/yarn, `@nestjs/cqrs`

## Library Constraints

- Always read package.json before suggesting libraries or tools

## Tools

- TypeScript LSP for all code navigation (type lookups, definitions, references)
  — never Read/Glob for these
- Context7 CLI for targeted API/library docs
- @RTK.md
