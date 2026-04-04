---
name: gdpr-scan
description: Full project scan of all event payloads for GDPR PII violations. Updates calibration catalog.
context: fork
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Edit
---

# GDPR PII Deep Audit

Scan every domain event, command, and value object type definition in the project for PII
that should not be in immutable event payloads. Update the calibration catalog with findings.

## Step 1 — Load calibration

Read `${CLAUDE_SKILL_DIR}/calibration.md` for the current PII catalog, safe fields, watch list,
and location granularity guide.

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

## Step 5 — Update calibration

Write newly discovered fields back to `${CLAUDE_SKILL_DIR}/calibration.md`:
- New PII fields → add to PII table
- New safe fields → add to Safe table
- New ambiguous fields → add to Watch List table

Preserve existing entries. Append new ones. Do not remove entries — only the user should
remove calibration entries (to correct false positives).
