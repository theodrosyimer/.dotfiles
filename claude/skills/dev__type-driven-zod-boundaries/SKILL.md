---
name: type-driven-zod-boundaries
description: How to implement type-driven domain modeling with Zod at boundaries. Covers domain type definitions (plain TypeScript), boundary schema patterns, operation-specific schemas (Create/Update/Form), type derivation with z.infer at boundaries, form integration with React Hook Form, use case validation, test data factories, and schema evolution/migration. Use when writing Zod schemas, defining boundary contracts, creating operation variants, wiring forms, or defining domain types. For the rules and constraints (where Zod lives, structural vs business validation, type vs interface), see the type-driven-zod-boundaries rule.
---

# Type-Driven Domain Modeling + Zod at Boundaries — How

Read the `type-driven-zod-boundaries` rule first for the constraints. This document is the implementation reference.

**Zod version: v4** — uses top-level format validators (`z.email()`, `z.uuid()`), `.extend()` (not `.merge()`), and v4 `.default()` semantics.

## Domain Types — Plain TypeScript

Domain types live inside the module and use plain `type` aliases. No Zod.

```typescript
// packages/modules/src/user/domain/types/user.types.ts

export type UserStatus = 'active' | 'suspended' | 'deleted'

export type User = {
  id: string
  email: string
  name: string
  status: UserStatus
  createdAt: Date
  updatedAt: Date
}
```

## Boundary Schema Pattern

Boundary schemas validate external input at module edges. They define **request** shapes — not the full domain type.

```typescript
// packages/modules/src/user/slices/create-user/create-user.schema.ts
import { z } from 'zod/v4'

export const CreateUserSchema = z.object({
  email: z.email(), // structural: format constraint (v4 top-level)
  name: z.string().min(1).max(100), // structural: shape constraint
  status: z.enum(['active', 'suspended', 'deleted']).default('active'),
})

// Boundary type derived from schema — never write manually alongside it
export type CreateUserRequest = z.infer<typeof CreateUserSchema>
```

## Operation-Specific Schemas

Derive from a base boundary schema. Never rewrite fields.

```typescript
// packages/modules/src/user/slices/update-user/update-user.schema.ts
import { z } from 'zod/v4'

export const UpdateUserSchema = z.object({
  id: z.uuid(),
  email: z.email().optional(),
  name: z.string().min(1).max(100).optional(),
  status: z.enum(['active', 'suspended', 'deleted']).optional(),
})
export type UpdateUserRequest = z.infer<typeof UpdateUserSchema>

// Patch a subset — pick only the fields that can change
export const PatchUserStatusSchema = z.object({
  id: z.uuid(),
  status: z.enum(['active', 'suspended', 'deleted']),
})
export type PatchUserStatusRequest = z.infer<typeof PatchUserStatusSchema>
```

```typescript
// packages/modules/src/user/slices/create-user/create-user-form.schema.ts
// Form — extend boundary schema with UI-only fields and cross-field refinements
import { CreateUserSchema } from './create-user.schema'
import { z } from 'zod/v4'

export const CreateUserFormSchema = CreateUserSchema.extend({
  confirmEmail: z.email(),
  acceptTerms: z.literal(true, { error: 'You must accept terms' }),
}).refine((data) => data.email === data.confirmEmail, {
  error: "Emails don't match",
  path: ['confirmEmail'],
})
export type CreateUserFormData = z.infer<typeof CreateUserFormSchema>
```

## Module File Location

```
packages/modules/src/{module}/
├── domain/
│   ├── types/
│   │   └── user.types.ts        ← plain TypeScript types (no Zod)
│   ├── entities/
│   │   └── user.entity.ts       ← entity uses plain types, business rules here
│   └── contracts/
│       └── user-repository.port.ts  ← plain TS interface, no Zod
├── slices/
│   ├── create-user/
│   │   ├── create-user.schema.ts         ← Zod boundary schema
│   │   ├── create-user-form.schema.ts    ← form extension of boundary schema
│   │   ├── create-user.handler.ts
│   │   └── create-user.handler.test.ts
│   └── update-user/
│       ├── update-user.schema.ts         ← Zod boundary schema
│       └── update-user.handler.ts
├── infrastructure/
│   └── repositories/
└── contracts/
    └── dtos/
```

## Entity Uses Plain Domain Types — Not Zod

The entity imports from `domain/types/`. It never imports Zod or boundary schemas.

```typescript
// packages/modules/src/user/domain/entities/user.entity.ts
import type { User } from '../types/user.types'
import { Entity } from '@modules/shared/domain/entities/entity'

export class UserEntity extends Entity<User> {
  constructor(data: User) {
    super(data)
  }

  // Business rules live here — not in boundary schemas
  canBeDeleted(): boolean {
    return this.props.status !== 'active'
  }

  suspend(): void {
    if (this.props.status === 'deleted') {
      throw new Error('Cannot suspend a deleted user')
    }
    this.update({ status: 'suspended', updatedAt: new Date() })
  }
}
```

## Use Case Validation at Boundary

Parse at the use case entry point — the boundary between external input and domain logic. The schema lives in the feature slice alongside the use case.

```typescript
// packages/modules/src/user/slices/update-user/update-user.handler.ts
import { UpdateUserSchema } from './update-user.schema'
import type { UserEntity } from '../../domain/entities/user.entity'
import type { IUserRepository } from '../../domain/contracts/user-repository.port'
import type { Executable } from '@modules/shared/domain/contracts/executable'

export class UpdateUserCommandHandler implements Executable<unknown, UserEntity> {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(input: unknown): Promise<UserEntity> {
    const validated = UpdateUserSchema.parse(input) // boundary parse

    const user = await this.userRepository.findById(validated.id)
    if (!user) throw new Error('User not found')

    user.update({ ...validated, updatedAt: new Date() })
    await this.userRepository.save(user)
    return user
  }
}
```

## Form Integration (React Hook Form)

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { CreateUserFormSchema, type CreateUserFormData } from '@modules/user/slices/create-user/create-user-form.schema'

export function CreateUserForm({ onSubmit }: { onSubmit: (data: CreateUserFormData) => void }) {
  const form = useForm<CreateUserFormData>({
    resolver: zodResolver(CreateUserFormSchema),
  })

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <input {...form.register('name')} placeholder="Name" />
      {form.formState.errors.name && (
        <span>{form.formState.errors.name.message}</span>
      )}

      <input {...form.register('email')} placeholder="Email" />
      <input {...form.register('confirmEmail')} placeholder="Confirm Email" />
      {form.formState.errors.confirmEmail && (
        <span>{form.formState.errors.confirmEmail.message}</span>
      )}

      <button type="submit">Create</button>
    </form>
  )
}
```

## Test Data Factories

Factory naming convention: `create` prefix + `Fixture` suffix. Domain types used for the shape, boundary schema for validation when needed.

```typescript
// packages/modules/src/user/domain/__tests__/fixtures/create-user.fixture.ts
import type { User } from '../../types/user.types'

export function createUserFixture(overrides: Partial<User> = {}): User {
  return {
    id: crypto.randomUUID(),
    email: 'test@example.com',
    name: 'Test User',
    status: 'active',
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  }
}
```

Usage in tests:

```typescript
const user = createUserFixture({ status: 'suspended' })
const admin = createUserFixture({ email: 'admin@example.com', name: 'Admin' })
```

## Schema Evolution

### Backward Compatible (additive)

```typescript
// Before
export const CreateUserSchema = z.object({
  email: z.email(),
  name: z.string(),
})

// After — optional field, no consumers break
export const CreateUserSchema = z.object({
  email: z.email(),
  name: z.string(),
  avatar: z.url().optional(),
})
```

### Breaking Change — Versioned Migration

```typescript
// Keep old schema for migration reads
const CreateUserV1Schema = z.object({
  email: z.email(),
  fullName: z.string(),
})

// New schema
const CreateUserV2Schema = z.object({
  email: z.email(),
  profile: z.object({
    firstName: z.string(),
    lastName: z.string(),
  }),
})

function migrateV1ToV2(v1: z.infer<typeof CreateUserV1Schema>): z.infer<typeof CreateUserV2Schema> {
  const [firstName = '', ...rest] = v1.fullName.split(' ')
  return {
    email: v1.email,
    profile: { firstName, lastName: rest.join(' ') },
  }
}
```

## Zod v4 Quick Reference (Key Changes from v3)

- **Top-level format validators**: `z.email()`, `z.uuid()`, `z.url()`, `z.base64()`, `z.nanoid()`, `z.cuid2()`, `z.ulid()`, `z.ipv4()`, `z.ipv6()` — replaces `z.string().email()`, `z.string().uuid()`, etc. (old forms still work but deprecated)
- **ISO date/time**: `z.iso.date()`, `z.iso.time()`, `z.iso.datetime()`, `z.iso.duration()`
- **Import**: `import { z } from 'zod/v4'` (or `from 'zod'` if package resolves to v4)
- **`.merge()` deprecated**: Use `.extend(other.shape)` or `z.object({ ...a.shape, ...b.shape })`
- **`.default()` matches output type**: Default value must be assignable to the output, not input. Use `.prefault()` for the old v3 behavior
- **`z.coerce` input type is `unknown`**: `z.input<typeof z.coerce.string()>` returns `unknown`, not `string`
- **Error customization — unified `error` parameter**: Replaces `message`, `errorMap`, `invalid_type_error`, `required_error` from v3. Simple: `z.string().min(5, { error: "Too short" })`. Conditional: `z.string({ error: (issue) => issue.input === undefined ? "Required" : "Not a string" })`. In `.refine()`: `{ error: "...", path: [...] }` (function-as-second-arg overload removed — use `superRefine()` for dynamic messages)
- **`z.record()` with enum keys is now exhaustive**: All enum keys must be present. Use `z.partialRecord()` for optional keys

## Quick Checklist

- [ ] Domain types (commands, events, entities) are plain TypeScript `type` aliases — no Zod
- [ ] Boundary schemas validate external input only — `z.infer` derives boundary types
- [ ] Operation variants use `.omit()` / `.partial()` / `.extend()` — no field duplication
- [ ] Structural constraints in boundary schemas; business rules in entities
- [ ] Form schema extends boundary schema (never duplicates it)
- [ ] Use case calls `.parse(input)` at entry point — schema co-located in feature slice
- [ ] Test factories named `createXxxFixture()` — use plain domain types, not Zod
- [ ] Inside module domain/: plain `type` / `interface` — no Zod imports in entities or ports
- [ ] Using Zod v4 top-level validators (`z.email()`, `z.uuid()`) — not deprecated `z.string().email()`
