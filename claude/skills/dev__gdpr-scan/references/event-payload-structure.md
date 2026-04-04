# Event Payload Structure for PII Scanning

This reference helps dev__gdpr-scan by describing event payload anatomy -- which fields carry user data, how payloads are structured, and where PII typically hides in event-sourced systems.

## Event Anatomy

Every business event has:
- **Name/type**: Verb phrase in past tense (e.g., "RideScheduled", "BookingRequested")
- **Data payload**: All data necessary to understand the business occurrence

### Events Must Be Denormalized and Data-Covering

All data necessary to understand the business process is contained within the events themselves. This means PII can appear in ANY event that records a user action or user-related state change.

**Exception**: Large binary blobs use the claim check pattern (URI reference instead of inline data). PII may exist in the referenced blob.

## Where PII Typically Appears

### Command Payloads (Input)
Commands carry user-submitted data. High PII risk:
- User registration commands: name, email, phone, address
- Profile update commands: any personal data field
- Booking/order commands: contact details, preferences
- Payment commands: billing address, payment method references

### Event Payloads (Recorded Facts)
Events record what happened. PII from commands propagates here:
- `UserRegistered`: name, email, phone
- `BookingRequested`: guest name, contact info, stay dates
- `PaymentProcessed`: billing address, last 4 digits
- `ProfileUpdated`: any changed personal fields

### Read Model Projections
Read models aggregate event data for queries. PII accumulates:
- User profile read models
- Booking detail read models
- Order history read models
- Search indexes (may contain names, locations)

### React Function Side Effects
The `react` function maps events to downstream commands. PII flows across streams:
- Notification stream receives user contact info
- Analytics stream may receive user behavior data
- External integrations forward user data to third parties

## The Four Domain Functions and PII Flow

```
Command (PII enters here)
    |
    v
decide(command, state) -> events (PII recorded here)
    |
    v
evolve(state, event) -> new state (PII in aggregate state)
    |
    v
project(events) -> read model (PII in query-side projections)
    |
    v
react(event) -> commands (PII propagates to other streams)
```

## PII Scanning Checklist

For each event stream, check:

- [ ] **Command payloads**: What user data enters via commands?
- [ ] **Event payloads**: What personal data is recorded in events?
- [ ] **Denormalized copies**: Same PII may exist in multiple events across time
- [ ] **Cross-stream propagation**: Does `react` forward PII to other streams?
- [ ] **Read model accumulation**: Do projections aggregate PII from multiple events?
- [ ] **Claim check references**: Do referenced blobs contain PII?

## GDPR-by-Design Patterns

### Forgettable Payloads
For user profiles and personal data:
- Store PII in a separate, deletable store keyed by user ID
- Events reference the user ID, not inline PII
- Deletion = remove from forgettable store; events remain valid (just missing PII fields)

### Crypto Shredding
For transactional contexts where PII must be in events:
- Encrypt PII fields in event payloads with per-user keys
- Deletion = destroy the encryption key
- Events become unreadable for that user's PII but structurally intact

### Rule: PII Out of Event Payloads from Day One
This project mandates GDPR-by-design: PII should NOT be in event payloads. Use Forgettable Payloads for user profiles, Crypto Shredding for transactional contexts.

## Event Stream Integration Risk

Fat events carrying full models across modules are an anti-pattern for PII:
- Thin events with IDs only -- let consumers look up their own data
- Each consumer's read model controls its own PII retention
- Reduces PII blast radius across bounded contexts
