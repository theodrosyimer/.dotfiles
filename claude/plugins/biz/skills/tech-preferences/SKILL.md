---
name: tech-preferences
description: >
  Generate or update a technical preferences document through an interactive interview.
  Use when the user says "set up tech preferences", "configure my stack", "what's my tech setup",
  or when another skill needs technical context and profiles/tech-preferences.md doesn't exist.
  Covers development philosophy, language/framework choices, architecture patterns, tooling,
  deployment, testing strategy, and code standards. Saved to profiles/tech-preferences.md.
---

# Tech Preferences Generator

## Purpose

Interview the user to build a comprehensive technical preferences document. Other skills reference this to make appropriate technology recommendations, generate code in the right style, and respect architecture decisions.

## Workflow

### Step 1: Check for Existing Preferences

```
profiles/tech-preferences.md
```

- If exists → ask if they want to **update** specific sections or **regenerate** entirely
- If missing → run full interview

### Step 2: Interactive Interview

Ask in **batches of 3-5 questions**. Skip sections the user flags as irrelevant (e.g., skip mobile if they only do web).

#### Batch 1: Development Philosophy
- Frontend-first, backend-first, or full-stack simultaneous?
- Domain-driven design, feature-driven, component-driven, or data-driven?
- Architecture default: monolith, microservices, modular monolith, serverless?
- Code organization: by technical layer or by feature/domain?
- Clean architecture, hexagonal, CQRS — any of these core to your approach?
- Testing methodology: TDD, BDD, write-after, minimal?

#### Batch 2: Language & Type System
- Primary language? (TypeScript, Python, Go, Rust, etc.)
- If TypeScript: strict mode? Additional strict options?
- Type vs interface preference?
- Comment language? (English, native language, bilingual)
- Documentation language? (Same as code or different?)

#### Batch 3: Frontend Stack
- **First ask**: Web, mobile, or hybrid? This determines the follow-up questions.
  - Mobile → React Native (Expo)? Flutter? Native?
  - Web → Next.js? TanStack Start? Vite + React? Vue? Svelte?
  - Hybrid → Which frameworks for each platform?
- State management? (built-in, Redux, Zustand, XState, depends on project)
- Styling? (Tailwind, CSS modules, styled-components, UI library)
- Form handling? (React Hook Form, Formik, TanStack Form, native)

#### Batch 4: Backend Stack
- Backend framework? (NestJS, Express, Fastify, Django, FastAPI, Go stdlib)
- API style? (REST, GraphQL, tRPC, server components)
- Database? (PostgreSQL, MySQL, SQLite, MongoDB, Supabase)
- ORM/query builder? (Drizzle, Prisma, TypeORM, Knex, raw SQL)
- Auth strategy? (better-auth, Clerk, Auth0, Supabase Auth, custom)

#### Batch 5: DevOps & Tooling
- Editor/IDE? (VS Code, Cursor, WebStorm, Neovim)
- Version control workflow? (feature branches, trunk-based, git flow)
- CI/CD? (GitHub Actions, GitLab CI, manual)
- Hosting? (Vercel, Netlify, VPS, AWS, Railway, self-hosted)
- Database hosting? (Supabase, managed service, Docker on VPS)
- Monorepo? (Turborepo + pnpm, Nx, single repo)

#### Batch 6: Quality & Standards
- Linting? (ESLint + Prettier config, Biome)
- Testing frameworks? (Vitest, Jest, Testing Library, Playwright)
- Code quality gates? (pre-commit hooks, PR reviews, CI checks)
- Performance monitoring? (Sentry, custom, as-needed)
- Technical debt approach? (regular refactoring, address when needed)

#### Batch 7: Libraries to Prefer & Avoid
- Any libraries you always use? (list with reasons)
- Any libraries you explicitly avoid? (list with reasons — e.g., "never Jest, use Vitest")
- Payment processing preference? (Stripe, PayPal, etc.)
- Email service? (Resend, SendGrid, SES)

### Step 3: Generate Preferences Document

Use `templates/preferences-template.md` as the output format. Fill every section. Mark skipped sections as `[Not specified — update later]`.

### Step 4: Save

Write to:

```
profiles/tech-preferences.md
```

Create `profiles/` if needed. Confirm the path to the user.

## Integration with Other Skills

- **saas-intake**: Uses stack preferences to pre-fill technical approach section
- **viability-analysis**: Phase 6 (technical feasibility) checks against preferences
- **github-strategy**: Uses CI/CD and collaboration preferences
- **builder subagent**: Loads this profile for all technical decisions

## Important Notes

- Respect opinionated choices — don't argue with preferences unless asked for opinions
- If the user mentions a library to avoid, note it prominently (these are usually strong opinions)
- The platform question (web/mobile/hybrid) should be asked FIRST before frontend details
- Capture the "why" behind choices when offered — helps other skills make better suggestions
- This document should feel like a technical README about the developer, not a survey response
