# 0002. Type-Driven Domain Modeling with Zod at Boundaries

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — pattern proven across all modules; Zod v4 migration confirms the boundary-only approach scales

**Reevaluation triggers**: Zod replaced by a superior validation library; TypeScript adds built-in runtime validation; team adopts Effect which provides its own schema layer (Effect/Schema).

## Context

The project needed a single source of truth for data shapes that provides both compile-time type safety and runtime validation. Maintaining separate TypeScript interfaces and validation logic creates drift — types say one thing, runtime says another.

Frontend-first development means schemas evolve rapidly as UI requirements are discovered. The validation approach must support iterative schema evolution without requiring manual type synchronization.

Key forces:
- Runtime validation needed at application boundaries (API inputs, module contracts, external data)
- TypeScript types alone can't catch runtime data issues
- Frontend-first development demands rapid schema iteration
- Forms, API validation, and database validation should share the same definitions
- Must work across the entire Turborepo monorepo

## Decision

**We will use plain TypeScript types for domain modeling and Zod schemas for validation at application boundaries only.**

Core rules:

1. **Type-driven domain modeling**: Domain commands, events, and entity types use plain TypeScript `type` aliases — no Zod deep inside the domain layer
2. **Zod at boundaries only**: Use Zod schemas at application layer edges and between modules (API inputs, inter-module contracts, external data such as DB results, third-party APIs, environment variables, file/config parsing). Derive boundary types with `z.infer<typeof Schema>` — never duplicate types manually alongside a schema
3. **Structural validation in schemas**: Format and shape constraints (email format, min/max length, positive numbers) belong in schemas
4. **Business rules in entities**: Business logic (can this booking be cancelled? is this listing valid?) belongs in domain entities and domain services, never in schemas
5. **No duplicate types**: If a type exists as `z.infer<typeof SomeSchema>`, never manually define an equivalent interface

```typescript
// ✅ CORRECT — Domain type: plain TypeScript
// packages/modules/src/user/domain/types/user.types.ts
export type User = {
  id: string
  email: string
  name: string
  createdAt: Date
}

// ✅ CORRECT — Boundary schema: Zod at API/module edge
// packages/modules/src/user/features/create-user/create-user.schema.ts
export const CreateUserSchema = z.object({
  email: z.string().email(),       // Structural validation at boundary
  name: z.string().min(1).max(100) // Structural validation at boundary
})
export type CreateUserRequest = z.infer<typeof CreateUserSchema>

// ❌ FORBIDDEN — Zod deep inside domain for entity types
export const UserSchema = z.object({ ... })
export type User = z.infer<typeof UserSchema>

// ❌ FORBIDDEN — manual interface duplicating a boundary schema
export interface CreateUserRequest {
  email: string
  name: string
}
```

## Consequences

### Positive

- Single maintenance point for validation + types
- Runtime validation catches data issues TypeScript cannot
- Schema evolution during frontend-first development is frictionless
- Form validation (react-hook-form + zodResolver), API validation, and module contracts all unified
- `drizzle-zod` integrates database schemas into the same system

### Negative

- Learning curve for Zod API (transforms, refinements, discriminated unions)
- Slightly more verbose than plain interfaces for simple data shapes
- Async transforms (sanitization) add complexity to schema definitions

### Neutral

- Zod is the dominant runtime validation library in the TypeScript ecosystem, so community support is strong

## Alternatives Considered

### Alternative 1: TypeScript Interfaces + Class-Validator

Rejected because it requires decorators (non-standard), creates two sources of truth (interface + decorated class), and doesn't integrate with react-hook-form's resolver pattern.

### Alternative 2: io-ts

Rejected due to steeper learning curve and less ecosystem integration compared to Zod. Functional pipe-based API is less intuitive for the team.

### Alternative 3: Yup

Rejected because Zod has better TypeScript inference, is more actively maintained, and has superior discriminated union support.

## References

- Zod documentation: https://zod.dev
- Related: [ADR-0001](0001-use-modular-monolith-as-default-architecture.md)
