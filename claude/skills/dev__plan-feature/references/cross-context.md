# Template: CROSS_CONTEXT Epic

Use this template for cross-domain features requiring coordination between multiple bounded contexts.

**Characteristics:**
- Cross-bounded context coordination
- Multiple entity interactions across contexts
- 5-10+ user stories
- Event-driven workflows likely
- External integrations possible

---

## Epic Template

```markdown
# Epic: [Epic Name]

## Summary
- **Complexity**: CROSS_CONTEXT
- **Domains Involved**: [domain1], [domain2]
- **Bounded Contexts**: [context1], [context2]

## Bounded Context Map

```
┌─────────────────────────────────────────────────────┐
│                    [Epic Name]                        │
├─────────────────────┬───────────────────────────────┤
│ [Context 1]         │ [Context 2]                    │
│ ├─ [Entity1]        │ ├─ [Entity3]                   │
│ └─ [Entity2]        │ └─ [Entity4]                   │
├─────────────────────┴───────────────────────────────┤
│ Dependencies:                                        │
│ • Context 2 depends on Context 1                     │
└─────────────────────────────────────────────────────┘
```

## Feature Breakdown

### Feature 1: [Context 1 Feature]
- **Context**: [context1]
- **Stories**: [PREFIX-001] to [PREFIX-003]
- **Dependencies**: None (depended-upon context — implement first)

### Feature 2: [Context 2 Feature]
- **Context**: [context2]
- **Stories**: [PREFIX-004] to [PREFIX-006]
- **Dependencies**: Context 1 (needs data from Context 1)

### Feature 3: Cross-Context Integration
- **Stories**: [PREFIX-007] to [PREFIX-009]
- **Dependencies**: Features 1 & 2

---

## User Stories by Context

### Context 1: [Context Name]

#### [PREFIX-001] CORE: [Primary Context1 Action]

**As a** [user type]
**I want to** [action in context1]
**So that** [benefit]

**Acceptance Criteria:**
```gherkin
Scenario: [Happy path]
  Given [precondition]
  When [action]
  Then [outcome]
```

**Business Rules:**
- [Rule 1]
- [Rule 2]

---

### Context 2: [Context Name]

#### [PREFIX-004] CORE: [Primary Context2 Action]

**As a** [user type]
**I want to** [action in context2]
**So that** [benefit]

**Acceptance Criteria:**
```gherkin
Scenario: [Happy path]
  Given [precondition — may reference Context1 state]
  When [action]
  Then [outcome]
```

**Business Rules:**
- [Rule 1]
- [Rule 2]

---

### Cross-Context Integration

#### [PREFIX-007] INTEGRATION: [Cross-Context Workflow]

**As a** [user type]
**I want to** [cross-domain action]
**So that** [end-to-end value]

**Acceptance Criteria:**
```gherkin
Scenario: Complete cross-context workflow
  Given [Context1 state]
  And [Context2 state]
  When [trigger action]
  Then [Context1 outcome]
  And [Context2 outcome]
  And [end user outcome]
```

---

## Implementation Phases

### Phase 1: Context 1 Core (Week 1)
| Story | Type | Notes |
|-------|------|-------|
| PREFIX-001 | CORE | Primary use case |
| PREFIX-002 | CORE | Secondary use case |
| PREFIX-003 | EDGE | Error handling |

### Phase 2: Context 2 Core (Week 2)
| Story | Type | Notes |
|-------|------|-------|
| PREFIX-004 | CORE | Primary use case |
| PREFIX-005 | CORE | Secondary use case |
| PREFIX-006 | EDGE | Error handling |

### Phase 3: Integration (Week 3)
| Story | Type | Notes |
|-------|------|-------|
| PREFIX-007 | INTEGRATION | Cross-context workflow |
| PREFIX-008 | INTEGRATION | Event handling |
| PREFIX-009 | UI | End-to-end UI |

---

## Cross-Context Dependencies

```
Contexts:
├─ [Context1]: owns [Entity1, Entity2]
│  └─ Responsibility: [what this context does]
├─ [Context2]: owns [Entity3, Entity4]
│  └─ Responsibility: [what this context does]

Dependencies:
├─ [Context2] depends on [Context1] — [reason]
└─ [Context3] depends on [Context1] — [reason]

NOTE: Communication patterns (Gateway, ACL, events) are
architecture decisions made during implementation.
See development/implement-feature.
```
```

---

## PRD.json Template

See `assets/templates/prd-cross-context.json` for the machine-consumable template.

> For implementation patterns (Gateway, ACL, event handler, TDD), see `development/implement-feature`.
