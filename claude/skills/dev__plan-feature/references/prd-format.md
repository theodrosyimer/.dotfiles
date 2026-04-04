## PRD Format Reference

### Domain Hierarchy

- **DOMAIN**: Large business area (e.g., `space`, `user`, `reservation`, `auth`, `payment`)
- **BOUNDED CONTEXT**: Business capability within domain with distinct ubiquitous language (e.g.,
  `listing`, `booking`, `management`)
- **USE CASE**: Specific action/workflow within bounded context (e.g., `create`, `edit`, `publish`,
  `book`, `cancel`)

### PRD.json Schema Types

```typescript
type StoryType = 'CORE' | 'EDGE' | 'UI' | 'INTEGRATION'
type Complexity = 'CRUD' | 'CQRS' | 'CROSS_CONTEXT'
type NFRCategory = 'performance' | 'accessibility' | 'security' | 'scalability' | 'observability' | 'compliance'

type UserStory = {
  id: string // Format: PREFIX-NUMBER (e.g., PR-001)
  title: string
  type: StoryType
  asA: string
  iWant: string
  soThat: string
  acceptanceCriteria: AcceptanceCriterion[] // min 1
  businessRules?: string[]
  minimalDataSchema?: Record<string, string> // Zod-like type hints
  dependencies?: string[] // Other story IDs
}

type Feature = {
  id: string
  name: string
  description: string
  priority: 'P0' | 'P1' | 'P2' | 'P3'
  status: 'planned' | 'in-progress' | 'done' | 'blocked'
  complexity: Complexity
  domain: string
  boundedContext: string
  nonFunctionalRequirements?: { category: NFRCategory; requirement: string }[]
  userStories: UserStory[] // min 1
}

type PRD = {
  product: string
  version: string // semver
  features: Feature[]
  implementationOrder?: { phase: number; name: string; stories: string[] }[]
  crossContextDependencies?: {
    contexts: { name: string; entities: string[]; responsibility: string }[]
    dependencies: { from: string; to: string; reason: string }[]
  }
  sharedConcepts?: Record<string, unknown>
}
```

Full Zod schema: `scripts/prd.schema.ts`. CLI validator: `scripts/validate-prd.ts`.

### Content Rules

- `complexity`: One of `CRUD`, `CQRS`, `CROSS_CONTEXT`
- `nonFunctionalRequirements`: Feature-level. Story-specific NFRs → express as Gherkin acceptance criteria instead
- `businessRules`: Prose descriptions only — do NOT classify where they go (entity vs service). That's implement-feature's job
- `minimalDataSchema`: Data discovery artifact from UI mockups / event modeling / domain experts. Zod-like type hints (`"spaceId": "string().uuid()"`)
- `crossContextDependencies`: Only for CROSS_CONTEXT. Context names, entity ownership, dependency directions — no Gateway/ACL/event decisions
- **PRD does NOT contain:** Architecture mapping, code patterns, communication pattern decisions, domain service/port classification

### PRD.md Alternative (Human-Readable)

```
DOMAIN: [e.g., space]
BOUNDED CONTEXT: [e.g., booking]
USE CASE: [e.g., reserve parking space]
BUSINESS VALUE: [1-2 sentences]
COMPLEXITY ASSESSMENT: [CRUD | CQRS | CROSS_CONTEXT]

USER STORY:
As a [user type], I want to [action] so that [business value]

ACCEPTANCE CRITERIA (Gherkin):
GIVEN [initial state]
WHEN [user action]
THEN [expected outcome]

BUSINESS RULES:
- [Rule 1]
- [Rule 2]

MINIMAL DATA SCHEMA:
- field1: string().uuid()
- field2: coerce.date()
```

### Traceability

```
prd.json (Specification)
    ├── acceptanceCriteria[].scenario → describe('Scenario: ...') in *.handler.test.ts
    ├── acceptanceCriteria[].then + .and[] → expect() assertions
    ├── businessRules[] → Entity methods OR domain service methods (decided by implement-feature)
    └── crossContextDependencies → Gateway/ACL/event patterns (decided by implement-feature)
```

### Resources

**Templates** (blank scaffolds): `assets/templates/prd-crud.json`, `prd-cqrs.json`, `prd-cross-context.json`

**Examples** (complete worked PRDs): `assets/examples/prd-parking-reservation.json`

**Validation**: `scripts/validate-prd.ts` checks schema structure, story ID uniqueness, dependency integrity, implementation order coverage, cross-context consistency, NFR quality, and completeness
