---
name: gdpr-scan
description: GDPR PII scanning methodology — classification rules, scanning patterns, risk levels. State managed by gdpr-scan agent.
context: fork
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# GDPR PII Scanning Methodology

Classification rules and scanning patterns for detecting PII in immutable event payloads.
Calibration state is managed by the gdpr-scan agent (`memory: project`) — this skill is
pure methodology.

## Step 1 — Calibration (provided by agent)

The calling agent provides calibration data (known PII fields, safe fields, watch list,
location granularity guide). If invoked standalone, read `${CLAUDE_SKILL_DIR}/calibration.md`
as seed.

## Step 2 — Discover all domain types

Glob for type definitions:
- `packages/modules/src/**/domain/events/**/*.ts`
- `packages/modules/src/**/domain/commands/**/*.ts`
- `packages/modules/src/**/domain/types/**/*.ts`
- `packages/modules/src/**/domain/value-objects/**/*.ts`
- `packages/modules/src/**/contracts/dtos/**/*.ts`

## Step 3 — Scan each file

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

## Step 4 — Report

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

## Step 5 — Report new fields for calibration

List all newly discovered fields in the report output (Step 4 "New Fields Discovered" section).
The calling agent is responsible for persisting these to calibration storage.
