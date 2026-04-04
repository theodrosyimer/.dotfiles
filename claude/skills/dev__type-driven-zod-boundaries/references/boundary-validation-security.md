# Boundary Validation Security

This reference helps dev__type-driven-zod-boundaries by defining what Zod schemas should validate at system boundaries for security (XSS, injection, format).

## Validation vs. Sanitization

- **Validation** (Zod): Ensures data conforms to expected schema/format. Rejects invalid input.
- **Sanitization**: Modifies/cleans input to remove potentially harmful content. Transforms input.

Zod itself does NOT sanitize -- it only validates. Sanitization is implemented via `.transform()` or external libraries.

## What Zod Schemas Must Validate at Boundaries

### String Inputs
- **Min/max length**: Prevent empty strings and buffer overflows
- **Format patterns**: Email (`z.string().email()`), URL (`z.string().url()`), datetime (`z.string().datetime()`)
- **Regex constraints**: Phone numbers, postal codes, custom formats
- **Enum restrictions**: `z.enum([...])` for known value sets

### Numeric Inputs
- **Range bounds**: `z.number().min(0).max(1000)`
- **Integer vs float**: `z.number().int()` when fractions are invalid
- **Positive/negative**: `z.number().positive()`

### Object Shape
- **Required vs optional**: `z.object({...})` with explicit optionality
- **No extra properties**: `.strict()` or `.strip()` to reject/remove unknown fields
- **Nested validation**: Compose schemas for nested objects

## Sanitization via Zod Transforms

Zod transforms apply sanitization AFTER validation passes:

```typescript
const userInputSchema = z.object({
  name: z.string()
    .min(1)
    .transform(val => val.trim()),                    // Trim whitespace

  email: z.string()
    .email()
    .transform(val => normalizeEmail(val)),            // Normalize email

  phone: z.string()
    .transform(val => val.trim().replace(/[^0-9+\-\s()]/g, '')),  // Strip non-phone chars

  comment: z.string()
    .transform(async val => sanitizeRichText(val)),    // HTML sanitization
})
```

## Platform-Specific Security Concerns

### Web (Expo Web)
- Full XSS protection required
- DOMPurify for rich text content
- Context-aware escaping (HTML, JS, CSS, URL contexts differ)
- JSX auto-escapes `{userInput}` but NOT `dangerouslySetInnerHTML`

### Mobile (React Native)
- No HTML DOM, so HTML injection not possible in native rendering
- BUT: data flows mobile -> backend -> web clients
- Escape for backend safety and future web compatibility
- API injection prevention (SQL, NoSQL, command injection)

### Backend
- Always validate regardless of frontend
- Defense in depth: input validation + output encoding + parameterized queries
- Same backend serves mobile, web, and API consumers

## Security Validation Checklist for Boundary Schemas

For each Zod schema at a system boundary:

- [ ] String lengths bounded (min and max)
- [ ] Format validated (email, URL, datetime, phone)
- [ ] Enums used for known value sets (not open strings)
- [ ] Numbers have range bounds
- [ ] Objects use `.strict()` or `.strip()` for unknown properties
- [ ] Rich text content has sanitization transform
- [ ] Email inputs normalized
- [ ] Phone inputs stripped of non-phone characters

## Architecture: Where Sanitization Lives

```
API Input
  -> Zod schema validates shape/format (boundary)
  -> Zod transforms sanitize (trim, normalize, escape)
  -> Handler receives clean data
  -> Entity enforces business rules (domain layer)
```

Sanitization happens at the boundary (Zod transforms), NOT in the domain layer. The domain layer trusts that data entering through the application boundary has been structurally validated and sanitized.

## Dev/Test vs Production Behavior

Per Zod at boundaries guidance:
- **Dev/Test**: Crash the application on validation error (fail fast)
- **Production**: Monitor and log the error (Sentry) without crashing

## Sources

- Input Sanitization & Validation Guide for TypeScript Applications (project docs)
- OWASP Input Validation Cheat Sheet
