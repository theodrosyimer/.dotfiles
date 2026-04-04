# Template: CQRS Feature

Use this template for multi-step workflow features with complex business rules within a single bounded context.

**Characteristics:**
- Multi-step workflows
- Complex business rules
- 3-5 user stories
- Domain services may be needed for multi-entity coordination
- Events may be involved

---

## Feature Template

```markdown
# Feature: [Feature Name]

## Summary
- **Complexity**: CQRS
- **Domain**: [domain]
- **Bounded Context**: [context]

## Workflow Overview

This feature involves a multi-step workflow:
1. [Step 1 description]
2. [Step 2 description]
3. [Step 3 description]

## User Stories

### [CORE] Stories

#### [PREFIX-001] [Primary Action]

**As a** [user type]
**I want to** [primary action]
**So that** [business value]

**Acceptance Criteria:**
```gherkin
Scenario: Happy path - [description]
  Given [precondition]
  When [action]
  Then [outcome]
  And [additional outcome 1]
  And [additional outcome 2]

Scenario: Business rule enforcement - [rule name]
  Given [precondition violating rule]
  When [action]
  Then [error outcome]
  And [state preserved]
```

**Business Rules:**
- [Rule 1]
- [Rule 2]
- [Rule 3]

---

#### [PREFIX-002] [Secondary Action]

**As a** [user type]
**I want to** [secondary action]
**So that** [business value]

**Acceptance Criteria:**
```gherkin
Scenario: [Description]
  Given [precondition]
  When [action]
  Then [outcome]
```

---

### [EDGE] Stories

#### [PREFIX-003] Handle [Edge Case]

**As a** [user type]
**I want to** have graceful handling of [edge case]
**So that** [protection/value]

---

### [UI] Stories

#### [PREFIX-004] [UI Component]

**As a** [user type]
**I want to** [UI interaction]
**So that** [user experience value]

---

## Implementation Plan

| Order | Story | Type | Dependencies | Notes |
|-------|-------|------|--------------|-------|
| 1 | PREFIX-001 | CORE | None | Primary use case |
| 2 | PREFIX-002 | CORE | PREFIX-001 | Secondary use case |
| 3 | PREFIX-003 | EDGE | PREFIX-001 | Error handling |
| 4 | PREFIX-004 | UI | PREFIX-001 | Components + hooks |
```

---

## PRD.json Template

See `assets/templates/prd-cqrs.json` for the machine-consumable template.

> For implementation patterns (entity, domain service, use case, TDD), see `development/implement-feature`.
