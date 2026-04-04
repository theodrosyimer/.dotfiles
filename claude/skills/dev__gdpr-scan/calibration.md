# GDPR PII Calibration — Event Payload Sentinel

Self-correcting catalog of PII classifications for this project's domain events,
commands, and boundary DTOs. Read by the PostToolUse hook agent and the `/gdpr-scan`
deep audit skill. Updated by the `/gdpr-scan` skill and by manual corrections.

---

## PII Fields (BLOCK — must use Forgettable Payload or Crypto Shredding)

| Module | Type | Field | Category | Reasoning |
|---|---|---|---|---|
| booking | `BookingCanceledEvent` | `reason` | Free text | User-supplied text may contain personal details, names, circumstances |
| listing | `SpaceRegisteredEvent` | `location.address` | Physical address | Street-level address is PII under GDPR |
| * | any event/command | `email` | Contact info | Direct personal identifier |
| * | any event/command | `phone` | Contact info | Direct personal identifier |
| * | any event/command | `name` | Contact info | Direct personal identifier |
| * | any event/command | `firstName` | Contact info | Direct personal identifier |
| * | any event/command | `lastName` | Contact info | Direct personal identifier |
| * | any event/command | `ip` | Network identifier | Personal data per GDPR (context-dependent) |
| * | any event/command | `coordinates` | Precise location | GPS-level location is PII |
| * | any event/command | `postalCode` / `zipCode` | Quasi-PII | High mosaic risk when combined with entity IDs |
| * | any event/command | `streetAddress` | Physical address | PII |

---

## Safe Fields (APPROVE — no PII concern)

| Field pattern | Category | Reasoning |
|---|---|---|
| `BookingId`, `GuestId`, `SpaceId`, `HostId` | Branded IDs | Opaque UUID v7 references, not PII themselves |
| `occurredAt`, `period`, `startDate`, `endDate` | Temporal | Timestamps alone don't identify individuals |
| `price`, `hourlyRate`, `amount` | Financial values | Amounts without association to identity are safe |
| `_tag`, `status` | Discriminants | Domain state markers |
| `spaceId`, `bookingId`, `hostId`, `guestId` | Entity references | ID fields referencing branded types |
| `country`, `region`, `department` | Coarse location | Too general to identify anyone |

---

## Watch List (flag with additionalContext, don't block)

| Module | Type | Field | Risk | Reasoning |
|---|---|---|---|---|
| listing | `SpaceRegisteredEvent` | `title` | Low | Could contain identifying info (e.g., "John's Studio") |
| * | any | `description` | Low-Medium | Free text — may contain personal details |
| * | any | `notes` | Low-Medium | Free text — may contain personal details |
| * | any | `comment` | Low-Medium | Free text — may contain personal details |
| * | any | `city` | Low (mosaic) | Safe alone, but combined with date + entity ID could narrow to individual |

---

## Location Granularity Guide

| Granularity | Alone | Combined with entity IDs | Verdict |
|---|---|---|---|
| Country | Safe | Safe | APPROVE |
| Region / Department | Safe | Safe | APPROVE |
| City | Safe | Low risk (mosaic) | APPROVE + watch |
| Postal / ZIP code | Quasi-PII | High risk (mosaic) | BLOCK |
| Street address | PII | PII | BLOCK |
| GPS coordinates | PII | PII | BLOCK |

GDPR principle: **data minimization** — store only the granularity the business logic needs.

---

## Calibration Corrections Log

Record overrides here when the sentinel misjudges. Format:
`[date] [field] [expected: BLOCK/APPROVE/WATCH] [actual: BLOCK/APPROVE/WATCH] [reasoning]`

<!-- Example:
[2026-04-02] booking.BookingRequestedEvent.guestId APPROVE (was flagged as PII — branded ID is safe)
[2026-04-02] listing.SpaceRegisteredEvent.title WATCH→BLOCK (contained host names in practice)
-->
