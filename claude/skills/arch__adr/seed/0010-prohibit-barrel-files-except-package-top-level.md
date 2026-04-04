# 0010. Prohibit Barrel Files Except at Package Top Level

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — no barrel-related issues since adoption; TypeScript performance measurably better

**Reevaluation triggers**: TypeScript resolves barrel file performance issues natively; monorepo tooling (Turborepo, pnpm) changes how package exports work; team size grows and longer import paths become a consistent complaint.

## Context

Barrel files (`index.ts` re-exporting from subdirectories) create hidden dependency chains, circular import risks, and bundle size issues in monorepos. When every directory has an `index.ts`, imports look clean (`from './entities'`) but the bundler loads everything re-exported from that barrel — even if only one item is needed.

In a Turborepo monorepo, barrel files compound the problem: TypeScript's module resolution follows the barrel chain across package boundaries, slowing type checking and creating unexpected dependency graphs.

## Decision

**We will prohibit barrel files (`index.ts` re-exports) everywhere except at the top level of each package in the monorepo.**

```
ALLOWED:
  ✅ packages/domain/src/index.ts                    (package entry point)
  ✅ packages/domain/src/booking/index.ts             (module entry point via package.json exports)

FORBIDDEN:
  ❌ packages/domain/src/booking/entities/index.ts    (subdirectory barrel)
  ❌ packages/domain/src/booking/types/index.ts      (subdirectory barrel)
  ❌ Any index.ts that only re-exports from siblings
```

Import style:

```typescript
// ✅ CORRECT — explicit file imports
import { BookingEntity } from '@repo/domain/booking/entities/BookingEntity'
import { CreateBookingSchema } from '@repo/domain/booking/features/create-booking/create-booking.schema'

// ❌ FORBIDDEN — barrel file import
import { BookingEntity, BookingSchema } from '@repo/domain/booking'
// (unless this is the package.json exports entry point)
```

Package-level exports in `package.json` are the only valid barrel mechanism:

```json
{
  "exports": {
    "./booking": "./src/booking/index.ts",
    "./user": "./src/user/index.ts"
  }
}
```

## Consequences

### Positive

- No hidden dependency chains — every import is explicit
- Faster TypeScript type checking — no barrel chain resolution
- Smaller bundles — tree shaking works on explicit imports
- No circular import risks from re-export chains
- Clear dependency graph — you can see exactly what each file depends on

### Negative

- Longer import paths — `from './entities/BookingEntity'` instead of `from './entities'`
- More verbose refactoring — renaming a file requires updating all import sites

### Neutral

- IDE auto-import handles the verbosity in practice

## Alternatives Considered

### Alternative 1: Barrel Files Everywhere

Rejected due to bundle size, circular import risks, and slow TypeScript resolution in monorepos.

### Alternative 2: Barrel Files with `isolatedModules`

Partially addresses the TypeScript performance issue but doesn't solve bundle size or circular import problems.

## References

- TypeScript performance wiki: "Barrel files" section
- Related: [ADR-0001](0001-use-modular-monolith-as-default-architecture.md)
