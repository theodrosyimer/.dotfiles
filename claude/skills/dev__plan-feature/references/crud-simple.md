# Template: CRUD Feature

Use this template for simple data management features with basic validation rules.

**Characteristics:**
- Single entity operations
- Basic validation rules
- 1-3 user stories
- No domain services needed

---

## Feature Template

```markdown
# Feature: [Feature Name]

## Summary
- **Complexity**: CRUD
- **Domain**: [domain]
- **Bounded Context**: [context]

## User Stories

### [PREFIX-001] CORE: Create [Entity]

**As a** [user type]
**I want to** create a new [entity]
**So that** [business value]

**Acceptance Criteria:**
```gherkin
Scenario: Successfully create [entity]
  Given I am an authenticated [user type]
  When I provide valid [entity] data
  Then a new [entity] is created with unique ID
  And the [entity] has default status

Scenario: Validation failure
  Given I provide invalid [entity] data
  When I attempt to create the [entity]
  Then an error is returned with validation details
  And no [entity] is created
```

**Business Rules:**
- [Rule 1 description]
- [Rule 2 description]

---

### [PREFIX-002] CORE: Update [Entity]

**As a** [user type]
**I want to** update an existing [entity]
**So that** [business value]

**Acceptance Criteria:**
```gherkin
Scenario: Successfully update [entity]
  Given I have an existing [entity]
  When I provide valid update data
  Then the [entity] is updated
  And updatedAt timestamp is refreshed

Scenario: Update non-existent [entity]
  Given the [entity] does not exist
  When I attempt to update it
  Then a "not found" error is returned
```

---

### [PREFIX-003] UI: [Entity] Form Component

**As a** [user type]
**I want to** use a form to manage [entity]
**So that** I can easily create and edit

---

## Implementation Plan

| Order | Story | Type | Dependencies |
|-------|-------|------|--------------|
| 1 | PREFIX-001 | CORE | None |
| 2 | PREFIX-002 | CORE | PREFIX-001 |
| 3 | PREFIX-003 | UI | PREFIX-001, PREFIX-002 |
```

---

## PRD.json Template

See `assets/templates/prd-crud.json` for the machine-consumable template.

> For implementation patterns (entity, schema, use case, TDD), see `development/implement-feature`.
