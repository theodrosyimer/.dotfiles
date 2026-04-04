# 0006. Use Vitest Over Jest

**Date**: 2025-01-01

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — Vitest has proven reliable across the entire monorepo

**Reevaluation triggers**: Vitest drops ESM or TypeScript support; a superior test runner emerges with better monorepo integration; Node.js built-in test runner becomes feature-competitive.

## Context

The project uses a Turborepo monorepo with TypeScript throughout. The testing framework must support fast execution, native ESM, and seamless TypeScript without additional transpilation configuration.

Jest requires `ts-jest` or `@swc/jest` for TypeScript support, has incomplete ESM support requiring experimental flags, and its module resolution conflicts with monorepo package boundaries. Configuration overhead increases with each package added to the monorepo.

## Decision

**We will use Vitest as the exclusive testing framework across the entire monorepo.**

- All test files use Vitest APIs (`describe`, `it`, `expect`, `vi`)
- Jest is explicitly forbidden — no `jest.fn()`, no `@jest/*` packages
- Vitest's native TypeScript and ESM support eliminates transpilation config
- Test configuration is minimal thanks to Vite's resolution handling monorepo packages

## Consequences

### Positive

- Native TypeScript support — no `ts-jest` configuration
- Native ESM — no experimental flags or module resolution hacks
- Vite-based resolution handles monorepo `workspace:*` packages naturally
- Compatible API surface with Jest (easy migration, familiar for developers)
- Watch mode is faster due to Vite's transform pipeline
- HMR-like test re-execution during development

### Negative

- Smaller ecosystem than Jest (fewer third-party matchers, though `@testing-library` works fine)
- Some CI environments have better Jest caching support

## Alternatives Considered

### Alternative 1: Jest

Rejected due to TypeScript transpilation overhead, incomplete ESM support, and monorepo module resolution conflicts. Configuration burden grows with each package.

## References

- Vitest documentation: https://vitest.dev
- Related: [ADR-0003](0003-use-fakes-over-mocks-for-testing.md), [ADR-0005](0005-test-business-behavior-at-use-case-boundary.md)
