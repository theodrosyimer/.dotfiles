# GDPR PII Calibration — Event Payload Sentinel

Self-correcting catalog of PII classifications for this project's domain events,
commands, and boundary DTOs. Read by the PostToolUse hook agent and the `/gdpr-scan`
deep audit skill. Updated by the `/gdpr-scan` skill and by manual corrections.

---

## PII Fields (BLOCK — must use Forgettable Payload or Crypto Shredding)

| Module | Type              | Field                    | Category           | Reasoning                                       |
| ------ | ----------------- | ------------------------ | ------------------ | ----------------------------------------------- |
| \*     | any event/command | `email`                  | Contact info       | Direct personal identifier                      |
| \*     | any event/command | `phone`                  | Contact info       | Direct personal identifier                      |
| \*     | any event/command | `name`                   | Contact info       | Direct personal identifier                      |
| \*     | any event/command | `firstName`              | Contact info       | Direct personal identifier                      |
| \*     | any event/command | `lastName`               | Contact info       | Direct personal identifier                      |
| \*     | any event/command | `ip`                     | Network identifier | Personal data per GDPR (context-dependent)      |
| \*     | any event/command | `coordinates`            | Precise location   | GPS-level location is PII                       |
| \*     | any event/command | `postalCode` / `zipCode` | Quasi-PII          | High mosaic risk when combined with entity IDs  |
| \*     | any event/command | `streetAddress`          | Physical address   | PII                                             |
| \*     | any event/command | `reason`                 | Free text          | User-supplied text may contain personal details |

---

## Safe Fields (APPROVE — no PII concern)

| Field pattern                                  | Category         | Reasoning                                        |
| ---------------------------------------------- | ---------------- | ------------------------------------------------ |
| `*Id` (branded types)                          | Branded IDs      | Opaque UUID references, not PII themselves       |
| `occurredAt`, `period`, `startDate`, `endDate` | Temporal         | Timestamps alone don't identify individuals      |
| `price`, `amount`, `rate`                      | Financial values | Amounts without association to identity are safe |
| `_tag`, `status`                               | Discriminants    | Domain state markers                             |
| `country`, `region`                            | Coarse location  | Too general to identify anyone                   |

---

## Watch List (flag with additionalContext, don't block)

| Module | Type | Field         | Risk         | Reasoning                                                                 |
| ------ | ---- | ------------- | ------------ | ------------------------------------------------------------------------- |
| \*     | any  | `title`       | Low          | Could contain identifying info (e.g., "John's Studio")                    |
| \*     | any  | `description` | Low-Medium   | Free text — may contain personal details                                  |
| \*     | any  | `notes`       | Low-Medium   | Free text — may contain personal details                                  |
| \*     | any  | `comment`     | Low-Medium   | Free text — may contain personal details                                  |
| \*     | any  | `city`        | Low (mosaic) | Safe alone, but combined with date + entity ID could narrow to individual |

---

## Location Granularity Guide

| Granularity                               | Alone     | Combined with entity IDs | Verdict         |
| ----------------------------------------- | --------- | ------------------------ | --------------- |
| Country                                   | Safe      | Safe                     | APPROVE         |
| Region / Department (French: département) | Safe      | Safe                     | APPROVE         |
| City                                      | Safe      | Low risk (mosaic)        | APPROVE + watch |
| Postal / ZIP code                         | Quasi-PII | High risk (mosaic)       | BLOCK           |
| Street address                            | PII       | PII                      | BLOCK           |
| GPS coordinates                           | PII       | PII                      | BLOCK           |

GDPR principle: **data minimization** — store only the granularity the business logic needs.

---

## Calibration Corrections Log

Record overrides here when the sentinel misjudges. Format:
`[date] [field] [expected: BLOCK/APPROVE/WATCH] [actual: BLOCK/APPROVE/WATCH] [reasoning]`

<!-- Entries added by /gdpr-scan or manual corrections go here -->

---

## Module Characteristics

Discovered by the `/gdpr-scan` command per project. Empty on first run — the scan
populates this section. Format: `module | characteristic_id | value | confidence | reason`.

| Module | Characteristic          | Value | Confidence | Reason                                                    |
| ------ | ----------------------- | ----- | ---------- | --------------------------------------------------------- |
| \*     | processes_children_data | false | low        | Cannot determine from code — verify business requirements |
| \*     | cross_border_transfer   | false | low        | Cannot determine — depends on deployment topology         |
