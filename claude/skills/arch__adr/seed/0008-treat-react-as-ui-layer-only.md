# 0008. Treat React and React Native as UI Layer Only

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — framework-agnostic domain layer has survived multiple UI refactors without touching business logic

**Reevaluation triggers**: Migration away from React/React Native entirely; adoption of a framework (e.g., Solid, Svelte) with a fundamentally different component model that makes the hook glue layer unnecessary; React Server Components changing the boundary between UI and business logic.

## Context

Frontend frameworks create strong lock-in when business logic is embedded in components. If business rules live inside React hooks or component state, switching to another framework (or even significantly restructuring the UI) requires rewriting business logic alongside presentation code.

The project uses Expo (React Native + Web), which already shares code across platforms. However, framework-specific patterns (React Query mutations, Context API, hook composition) should not contain business logic — they should only bridge the UI to the domain layer.

## Decision

**We will treat React/React Native as pure UI execution environments. Business logic lives in the domain layer, and custom hooks serve only as a glue layer between UI and use cases.**

Three-layer separation:

```
COMPONENTS (React/RN):
  ✅ Render UI based on props and hook state
  ✅ Handle user interactions by calling hook methods
  ✅ Display loading/error states from hooks
  ✅ Manage local UI state (form inputs, modal visibility)
  ❌ No business logic, no direct API calls, no data transformations

CUSTOM HOOKS (Glue Layer):
  ✅ Inject dependencies via Context
  ✅ Call use cases and domain services
  ✅ Handle React-specific side effects (cache invalidation, routing)
  ✅ Transform domain data for UI consumption
  ❌ No business rules — delegate everything to use cases

DOMAIN LAYER (Framework-Agnostic):
  ✅ Contains all business logic
  ✅ Pure TypeScript — no React, no framework dependencies
  ✅ Use cases implement the Executable pattern
  ✅ Tested independently at use case boundary
```

Dependency injection via React Context:

```typescript
// Container setup — framework agnostic
const container = createFrontendContainer({ environment, apiBaseUrl })

// React-specific provider — lives in app, not in packages
<DependenciesProvider dependencies={container}>
  <App />
</DependenciesProvider>

// Hook bridges domain to React
function useCreateBooking() {
  const { createBookingUseCase } = useDependencies()
  return useMutation({
    mutationFn: createBookingUseCase.execute.bind(createBookingUseCase)
  })
}
```

## Consequences

### Positive

- Framework migration requires only rewriting UI layer — domain logic unchanged
- Same use cases power tests, frontend dev fakes, and production
- Clean testability — domain tested without React, components tested for UI contracts only
- Expo's cross-platform nature benefits from framework-agnostic business logic

### Negative

- More boilerplate — hooks are thin wrappers that feel redundant for simple CRUD
- Context-based DI is less powerful than proper DI containers (no auto-resolution)
- Developers must resist the temptation to add "just a little" business logic in hooks

### Neutral

- React Query / TanStack Query integration happens in hooks, not in domain

## Alternatives Considered

### Alternative 1: Business Logic in Components/Hooks

Rejected because it creates framework lock-in. Business rules embedded in React hooks can't be reused with a different framework and can't be tested without React testing utilities.

### Alternative 2: Full DI Container (InversifyJS)

Rejected as overly complex for the current team size. React Context provides sufficient DI capability. Can revisit if dependency graph complexity warrants it.

## References

- Related: [ADR-0001](0001-use-modular-monolith-as-default-architecture.md), [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md)
