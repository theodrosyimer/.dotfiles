# Convention Rule Template

Use this template when defining a convention rule for `/convention-enforcer`.

## Rule Definition

```
CONVENTION: <name>
DESCRIPTION: <what the convention requires — one sentence>

WHAT COMPLIANCE LOOKS LIKE:
- <pattern 1>
- <pattern 2>

WHAT VIOLATIONS LOOK LIKE:
- <anti-pattern 1>
- <anti-pattern 2>

SCOPE:
- Files: <glob patterns, e.g., **/domain/**/types.ts>
- Layers: <domain | infrastructure | contracts | all>

KNOWN EXCEPTIONS:
- <module or file that intentionally deviates, with reason>
```

## Example: Branded Domain IDs

```
CONVENTION: branded-domain-ids
DESCRIPTION: All domain entity IDs must use branded Zod types, not plain strings

WHAT COMPLIANCE LOOKS LIKE:
- `type BookingId = z.infer<typeof BookingId>` with `const BookingId = z.string().brand('BookingId')`
- ID types defined in `domain/types/` or `domain/value-objects/`

WHAT VIOLATIONS LOOK LIKE:
- `type BookingId = string` (plain string alias)
- `id: string` in entity types without branding
- Using `z.string()` without `.brand()` for ID fields at domain boundaries

SCOPE:
- Files: **/domain/**/types.ts, **/domain/**/value-objects/*.ts, **/domain/**/entities/*.ts
- Layers: domain

KNOWN EXCEPTIONS:
- src/core/types/id.ts — base ID type definition, intentionally unbranded
```

## Example: Discriminated Union State Modeling

```
CONVENTION: tagged-discriminated-unions
DESCRIPTION: All domain states must use _tag discriminated unions, not boolean flags or status enums

WHAT COMPLIANCE LOOKS LIKE:
- `type BookingState = NoBooking | PendingBooking | ConfirmedBooking`
- Each variant has `_tag: 'NoBooking'` (literal type)
- `satisfies` used on const declarations to preserve literal types

WHAT VIOLATIONS LOOK LIKE:
- `status: 'pending' | 'confirmed'` (string enum instead of tagged union)
- `isConfirmed: boolean` (boolean flag instead of state variant)
- Missing `_tag` field on union variants

SCOPE:
- Files: **/domain/**/entities/*.ts, **/domain/**/types.ts
- Layers: domain

KNOWN EXCEPTIONS:
- Gateway DTOs and API boundaries intentionally use nullable fields or status enums (not _tag)
```
