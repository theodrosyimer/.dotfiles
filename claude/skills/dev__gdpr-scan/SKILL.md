---
name: gdpr-scan
description: GDPR PII scanning methodology + module characteristic assessment. Classification rules, scanning patterns, risk levels, and gdpr-modules.json output for the decision matrix. Calibration state managed by the gdpr-scan agent (memory: project).
context: fork
allowed-tools: Read, Grep, Glob
---

# GDPR PII Scanning Methodology

Classification rules and scanning patterns for detecting PII in immutable event payloads,
plus module-level characteristic assessment for the GDPR decision matrix.

Produces two outputs:

1. **Markdown report** — human-readable PII audit
2. **gdpr-modules.json** — machine-readable module inventory for the decision matrix app

## Step 1 — Calibration (provided by agent)

The calling agent provides calibration data (known PII fields, safe fields, watch list,
location granularity guide, module characteristics). If invoked standalone, read
`${CLAUDE_SKILL_DIR}/calibration.md` as seed.

## Step 2 — Discover all domain types

Glob for type definitions:

- `packages/modules/src/**/domain/events/**/*.ts`
- `packages/modules/src/**/domain/commands/**/*.ts`
- `packages/modules/src/**/domain/types/**/*.ts`
- `packages/modules/src/**/domain/value-objects/**/*.ts`
- `packages/modules/src/**/contracts/dtos/**/*.ts`

Also discover module boundaries:

- `packages/modules/src/*/` — each directory is a module
- Check for `domain/`, `infrastructure/`, `slices/`, `contracts/` subdirs

## Step 3 — Scan each file for PII

For each file, read it and extract all type/interface definitions. For each field:

1. **Check against calibration catalog** — known PII, known safe, or watch list
2. **Check field name patterns** — match against PII field names (email, phone, name, address,
   ip, coordinates, postalCode, zipCode, streetAddress)
3. **Check type patterns** — `string` fields in event payloads are higher risk than branded IDs
4. **Check location granularity** — apply the granularity guide for location fields
5. **Flag free-text fields** — any `string` field that could contain user-supplied content
   (reason, description, notes, comment, title)
6. **Check forgettable payload derivation** — if a `*Payload` type exists, verify it uses
   `Pick<*Command, ...>` to derive from the command type. Standalone payload types that
   duplicate command fields are a drift risk — flag them.

## Step 4 — Assess module characteristics

For each discovered module, assess ALL 13 characteristics. Read the relevant source files
to determine each characteristic. Apply the confidence rules below.

### The 13 characteristics

**Financial & Regulatory:**

- `tax_retention` — Look for financial/invoice/payment terminology + check ADRs/docs for
  documented retention requirements. Confidence: always LOW unless explicitly documented.
- `processes_payment_instruments` — Check if raw card/bank data flows through the module or
  if delegated to Stripe/processor. Confidence: HIGH if Stripe SDK used and no card fields.
- `handles_escrow` — Look for escrow/hold/split/release patterns in domain events/entities.
  Confidence: HIGH from domain events.

**Data Ownership & Sensitivity:**

- `pii_authority` — Check if module owns the canonical PII store (personal_data table, user
  entity with name/email/phone). Confidence: HIGH from schema detection.
- `stores_health_data` — Look for health/medical/wellness/disability field names.
  Confidence: HIGH from field analysis.
- `processes_children_data` — Cannot determine from code. Confidence: always LOW.
- `stores_geolocation` — Look for lat/lng/coordinates/GPS/latitude/longitude fields.
  Confidence: HIGH from field analysis.
- `stores_user_communications` — Look for message/chat/thread/conversation entities.
  Confidence: HIGH from entity detection.

**Cross-Module & Integration:**

- `shows_cross_data` — Check if module's projections/queries import from other modules'
  gateways/contracts. Confidence: MEDIUM — import exists but actual PII flow uncertain.
- `triggers_other` — Check if module's events are imported by other modules' reactors/handlers.
  Confidence: MEDIUM from import graph.
- `shares_data_third_party` — Check for SDK imports (Resend, Stripe, Expo Push, Sentry).
  Confidence: HIGH for detected SDKs, LOW for undetected integrations.
- `cross_border_transfer` — Cannot determine from code. Confidence: always LOW.

**Processing & Automation:**

- `automated_decisions` — Look for scoring/ranking/recommendation/ML patterns.
  Confidence: MEDIUM from code patterns.

### Confidence assignment rules

```
HIGH:   AST/code clearly confirms or denies the characteristic
        (e.g., personal_data table found → pii_authority = true, HIGH)
        (e.g., no financial schemas at all → tax_retention = false, HIGH)

MEDIUM: Code has a signal but context is ambiguous
        (e.g., 'location' field could be city name or GPS coordinates)
        (e.g., cross-module import exists but unclear if PII flows through)

LOW:    Cannot determine from code — requires business/legal/deployment context
        Always LOW for: tax_retention, processes_children_data, cross_border_transfer
```

## Step 5 — PII audit report (markdown)

Output a structured report:

```
## GDPR PII Audit Report

### Violations (BLOCK)
- [module] [EventType].[field] — [category]: [reasoning]

### Watch List (review needed)
- [module] [EventType].[field] — [risk level]: [reasoning]

### Safe (APPROVE)
- [module] [EventType].[field] — [category]

### New Fields Discovered
- [module] [EventType].[field] — [classification]: [reasoning]

### Summary
- Files scanned: N
- Events/commands analyzed: N
- PII violations: N
- Watch list items: N
- New fields cataloged: N
```

## Step 6 — Module inventory output (gdpr-modules.json)

Write `gdpr-modules.json` to the project root. Format:

```json
{
  "version": "1.0",
  "generatedBy": "gdpr-scanner + claude-code",
  "generatedAt": "<ISO 8601 datetime>",
  "modules": [
    {
      "name": "<module name>",
      "classification": "<core_es | supporting_es | supporting_crud | generic>",
      "piiExamples": "<comma-separated PII fields found>",
      "lawfulBasis": "<Art. 6.1.x or empty if unknown>",
      "retention": "<retention period or empty if unknown>",
      "notes": "<assessment notes>",
      "characteristics": {
        "<characteristic_id>": {
          "value": true,
          "confidence": "high",
          "reason": "<why this was determined>"
        }
      }
    }
  ]
}
```

All 13 characteristic IDs MUST be present for every module.

Classification rules:

- Has `domain/events/`, uses decide/evolve pattern → `core_es` or `supporting_es`
- Has `domain/` but no events, uses repository pattern → `supporting_crud`
- Wraps external service (Clerk, Resend) → `generic`
- Core business logic (primary revenue-generating modules) → `core_es`
- Supporting business logic (user profile, payment, review) → `supporting_es`

## Step 7 — Report new fields for calibration

List all newly discovered fields in the report output (Step 5 "New Fields Discovered" section).
The calling agent is responsible for persisting these to calibration storage.

## Reference files

- `${CLAUDE_SKILL_DIR}/calibration.md` — seed calibration data (PII fields, safe fields, watch list, location granularity, module characteristics)
- `${CLAUDE_SKILL_DIR}/references/event-payload-structure.md` — event anatomy and PII flow through decide/evolve/project/react
