---
name: react-patterns
description: >
  React/React Native UI architecture patterns. Separates generic components (pure UI blocks),
  domain components (business-context), custom hooks (glue layer to domain logic), and
  Context-based dependency injection. Emphasizes framework-agnostic domain — React is just
  a UI execution environment.
when_to_use: >
  Trigger when building React/React Native components, creating custom hooks, implementing UI
  layer separation, setting up dependency injection for React, or ensuring domain logic stays
  out of components.
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
