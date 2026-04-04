# 0018. Separate Core Primitives from Shared Utilities

**Date**: 2026-03-18

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — litmus test has proven unambiguous for every new file placed since the split

**Reevaluation triggers**: A third category emerges that the binary litmus test cannot classify; monorepo restructuring moves core/ to its own package (making the directory-level split moot); LLM agents consistently misplace files despite the naming convention.

## Context

The `packages/modules/src/shared/` directory grew to contain fundamentally different kinds of code under one umbrella: architectural primitives that every module depends on (`Entity<T>`, `Executable`, `Result`, `ApplicationException`, port definitions for `Clock`, `EventStore`, `IdProvider`) alongside convenience utilities that only some modules use (`string.ts`, `utility-types.ts`, `test-dsl.ts`, observability decorator).

The name `shared` describes *how* the code is consumed (multiple modules use it) but not *what it is* or *how critical it is*. A developer looking at `shared/` can't tell whether deleting `entity.ts` would break the entire architecture or just one helper function in one module. This matters for three reasons: it affects how carefully code changes are reviewed, it determines what belongs here vs in a module, and it signals to LLM agents (Claude Code, Cursor) what they can safely modify.

The problem surfaced concretely when organizing infrastructure port definitions. `Clock`, `EventStore`, and `IdProvider` are port interfaces — domain-level contracts that infrastructure must satisfy. They were living in `shared/infrastructure/` alongside their implementations (`FixedClock`, `SystemClock`). The name `infrastructure/` inside `shared/` was misleading because port interfaces aren't infrastructure — they're architectural primitives that define the shape of the system. But splitting ports from implementations would violate the project's colocation principle (keep things that change together close together).

This decision builds on [ADR-0001](0001-use-modular-monolith-as-default-architecture.md) (modular monolith architecture) and [ADR-0015](0015-capture-time-in-imperative-shell-via-clock-port.md) (clock port pattern).

Key forces:
- `Entity<T>`, `Executable`, `Result` are load-bearing — every module's foundation depends on them
- Port definitions (`Clock`, `EventStore`, `IdProvider`) and their implementations change together — colocation is important
- String helpers and test utilities are convenience code — important but not architectural
- LLM agents need clear signals about what's safe to modify vs what requires careful review
- The split must be simple enough that every new file has an obvious home

## Decision

**We will split `shared/` into `core/` (load-bearing architectural primitives) and `shared/` (convenience utilities), using a single litmus test to decide placement.**

### The litmus test

```
PLACEMENT RULE:

  If deleting it breaks EVERY module → src/core/
  If deleting it breaks only consumers → src/shared/
```

This test is binary and decisive. There's no third category, no "it depends." Every file has exactly one correct home.

### Directory structure

```
src/core/                           → Load-bearing primitives
  entity.ts                         → Base class all entities extend
  executable.ts                     → Interface all use cases implement
  result.ts                         → Discriminated union for error handling
  clock/                            → Port + adapters colocated
    clock.ts                        → Port interface
    fixed-clock.ts                  → Test adapter
    system-clock.ts                 → Production adapter
  event-store/                      → Port definition
    event-store.ts
  id-provider/                      → Port definition
    id-provider.ts
  errors/                           → Error infrastructure
    application-exception.ts
    problem-details.factory.ts
    problem-details.model.ts
  types/
    instant.ts

src/shared/                         → Convenience utilities
  helpers/
    string.ts
    utility-types.ts
  infrastructure/
    observability/
      observability.decorator.ts
  tests/
    test-dsl.ts
```

### Organization principles

Concern-based subdirectories inside `core/`, not pattern-based. Each subdirectory is named for *what it's about*, not *what architectural role it plays*:

```
NAMING:
  ✅ clock/          → the concern (what is this about?)
  ✅ event-store/    → the concern
  ✅ errors/         → the concern
  ❌ ports/          → the pattern (what role does this play?)
  ❌ infrastructure/ → the layer (misleading for port definitions)
```

Port definitions and their implementations live together in the same concern directory because they change together. `clock/clock.ts` (the interface) and `clock/fixed-clock.ts` (the test adapter) are colocated because adding a method to the port requires updating both. This follows the same colocation principle used inside modules (`infrastructure/event-store/` holds both the real adapter and the fake).

## Consequences

### Positive

- The litmus test makes placement unambiguous — no discussion needed for new files
- `core/` signals "handle with care" to both developers and LLM agents — changes here require careful review because they affect every module
- `shared/` signals "convenience" — changes here are lower risk, affecting only direct consumers
- Concern-based directories inside `core/` are self-documenting — `core/clock/` is discoverable by what it does
- Port and implementation colocation is preserved — no scattering of related files

### Negative

- Two directories instead of one — every new shared file requires answering "core or shared?"
- Import paths change for everything that was in `shared/` — mechanical refactor across the codebase
- Some files are borderline (e.g., `result.ts` could be argued either way) — the litmus test resolves these but the answer may feel surprising

### Neutral

- The split is a monorepo-level concern — module-internal structure (`domain/`, `slices/`, `infrastructure/`, `contracts/`) is unchanged
- LLM agent skills and rules that reference `shared/` paths need updating to reference `core/` or `shared/` correctly

## Alternatives Considered

### Alternative 1: Rename shared/ to core/ entirely (no split)

Keep one directory but rename it to signal importance. Rejected because it loses the distinction between load-bearing primitives and convenience utilities. String helpers living in `core/` sends the wrong signal about their criticality.

### Alternative 2: Keep shared/ as-is with a README explaining the distinction

Document the difference without enforcing it structurally. Rejected because documentation doesn't prevent misplacement — the structure itself should encode the rule. A developer creating a new file should know where it goes from the directory name, not from reading a README.

### Alternative 3: Three directories (core/, shared/, infrastructure/)

Separate port definitions into their own `infrastructure/` directory at the monorepo level. Rejected because it violates the colocation principle — port interfaces and their implementations change together and should live together. Also, `infrastructure/` at the monorepo level conflicts with `infrastructure/` inside each module.

## References

- Related: [ADR-0001](0001-use-modular-monolith-as-default-architecture.md) (modular monolith architecture)
- Related: [ADR-0015](0015-capture-time-in-imperative-shell-via-clock-port.md) (clock port pattern)
