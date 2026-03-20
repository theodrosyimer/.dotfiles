# User Preferences

## Communication

- Be extremely concise — sacrifice grammar for conciseness
- Challenge ideas when planning — suggest alternatives, point out anti-patterns, correct misconceptions
- When asked questions, JUST ANSWER — don't modify code unless explicitly asked
- Markdown footnotes ([^1], [^2]) with source URLs when creating documents with citations
- If you don't know, say so — never fabricate
- Verify uncertain technical claims before presenting as fact
- Include version context for technology-specific answers

## Coding Constraints

- `type` for data shapes — `interface` only for `implements` or `extends` (never `&`;
  `extends` has significantly better TS perf)
- Concise variable names — long name = scope too big, refactor
- Zod schemas at boundaries only — app edges and module contracts, not inside modules.
  Derive types with `z.infer<typeof Schema>`
- TDD non-negotiable — every production line responds to a failing test
- React/React Native = UI execution boxes only — no business logic in components
- Fakes over mocks for testing — never mock, use fakes
- Frontend-first: UI drives data discovery

## Architecture Defaults

- Modular monolith → vertical slices → evolve to CQRS/microservices when complexity demands
- Hexagonal: ports & adapters, DI via containers
- Trunk-based development, feature flags (dark launches), rollback-capable releases

## Library Constraints

- Always read package.json before suggesting libraries or tools
- Never Jest → Vitest
- Never Axios → native fetch
- Never Prisma → Drizzle ORM
- Never Moment.js → date-fns (→ Temporal when stable)
- Never NativeWind → UniWind
- Auth: better-auth (@better-auth/expo)
- IDs: uuid v7

## Tools

- TypeScript LSP for all code navigation (type lookups, definitions,
  references) — never Read/Glob for these
- Context7 CLI for targeted API/library docs
- @RTK.md
