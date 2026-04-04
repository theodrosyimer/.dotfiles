---
name: react-patterns
description: React/React Native UI patterns with components, custom hooks, and dependency injection. Use when building React components, creating hooks, or implementing UI layer separation. Covers component-only presentation logic, hooks as glue layer to domain, Context-based DI, and framework-agnostic architecture.
---

# React/React Native Patterns

## Core Principle

**React is just a UI execution environment.** Components handle presentation ONLY. Business logic lives in the domain layer.

## Component Separation

**Generic** is about flexibility.
**Domain** is about context.

### ✅ Generic Components

→ Pure UI building blocks
→ No business logic
→ Reusable across the entire app

Examples:
• Button
• Input
• Modal
• Card

### ✅ Domain Components Must Only:

- Render UI elements based on props/state
- Handle user interactions by calling hooks
- Display loading/error states
- Manage local UI state (form inputs, modals)

→ Built from generics
→ Contain custom hooks using use-case
→ Represent real product meaning

Examples:
• BackButton
• CheckoutButton
• UserSettingsForm

### ✅ Custom Hooks Must Only:

- Inject dependencies via Context
- Call use cases and domain services
- Handle React-specific side effects
- Transform domain data for UI
- Manage async state

### ❌ Never Allow:

- Business logic in components
- Direct API calls in components
- Framework dependencies in domain layer

See: [references/ui-layer-separation.md](references/ui-layer-separation.md)

## Custom Hooks Patterns

See: [references/custom-hooks.md](references/custom-hooks.md)

## Dependency Injection

See: [references/dependency-injection.md](references/dependency-injection.md)

## Related Skills

- **architecture/frontend-first-workflow.md** - Overall methodology
- **architecture/domain-modeling** - Business logic placement
- **development/type-driven-zod-boundaries** - Form validation
