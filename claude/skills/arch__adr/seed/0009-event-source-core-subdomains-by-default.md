# 0009. Event Source Core Subdomains by Default

**Date**: 2026-03-26

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — Listing and Booking already use full ES in practice; this formalizes what
converged naturally

**Reevaluation triggers**: ES overhead demonstrably slows MVP delivery for a new core subdomain; a
supporting subdomain classified as CRUD reveals a missed replay/audit need in production; the team
grows and ES onboarding cost becomes a bottleneck.

## Context

The original version of this ADR established "default to simple CRUD, escalate to CQRS when business
complexity demands it" with a 3+ business rules threshold as the migration trigger. In practice,
both core subdomains with active implementations — Booking and Listing — converged on full event
sourcing (decide/evolve/project/react) independently, contradicting the CRUD-first default.

The Listing module (Space Catalog) was classified as "SIMPLE CRUD" in ADR-0000 but was implemented
with the full ES pattern: state-level dispatch in decide/evolve (ADR-0012), ADT lifecycle types
(`InitialSpaceState` → `RegisteredSpace` → `AvailableSpace` ↔ `OccupiedSpace` → `DelistedSpace`),
cross-stream integration via react + `BookingEventListener`, and event store persistence. The state
machine and cross-context integration demanded ES naturally.

This revealed that the decision axis should not be complexity-based (3+ business rules) but
**strategic classification-based** (core vs supporting vs generic). Core subdomains justify ES
because:

- **Replay** enables projecting new read models from existing events without data migrations
- **Audit trail** covers the money path end-to-end (Space Catalog → Reservation → Payment)
- **Debugging** via event replay reproduces exact state at any point in time
- **Schema evolution** via new `project` functions backfills views from historical events
- **Testing** maps directly to given/when/then on event streams

Greg Young explicitly warns against ES everywhere[^1], and Vlad Khononov recommends ES for core
subdomains specifically, with Transaction Script or Active Record for supporting/generic[^2]. The
decision to extend ES selectively to supporting subdomains (UserProfile) is based on concrete replay
value for customer support and GDPR audit — not blanket application.

## Decision

**We will event source all core subdomains by default and evaluate supporting subdomains
individually based on replay/audit value.**

```
DECISION AXIS: Strategic subdomain classification (ADR-0000)

CORE SUBDOMAINS → Event Sourced (decide/evolve/project/react):
  ✅ Space Catalog (Listing) — already implemented
  ✅ Reservation (Booking) — already implemented
  ✅ Discovery/Search — projection consumer over Listing + Booking event streams
  ✅ Payment Orchestration — escrow lifecycle, refund replay, audit trail

SUPPORTING SUBDOMAINS → Evaluate replay/audit value individually:
  ✅ User Profile — ES justified: customer support replay, GDPR audit trail
  ⏳ Review & Rating — CRUD for now, re-evaluate post-MVP
  ⏳ Messaging — CRUD for now, re-evaluate post-MVP

GENERIC SUBDOMAINS → CRUD / Wrapper (no ES):
  ✅ IAM — better-auth owns state; ES on a wrapper adds no value
  ✅ Notification — dumb pipe, event consumer only, no domain state to source
```

```
WHEN TO USE ES FOR A SUPPORTING SUBDOMAIN:

  Ask: "Would replaying this subdomain's event stream provide concrete value?"

  CONCRETE VALUE:
    ✅ Customer support can walk through a user's actions to debug account state
    ✅ GDPR "right to explanation" — show what happened to someone's data
    ✅ New business view needs backfilling from historical events
    ✅ Cross-context debugging requires tracing events across the money path

  NOT SUFFICIENT:
    ❌ "Audit trail might be useful someday" — use structured logging instead
    ❌ "Consistency with other modules" — uniformity is not a business need
```

The 3+ business rules threshold from the original version of this ADR becomes a secondary signal for
supporting subdomains that aren't initially event-sourced — if a CRUD supporting module accumulates
complexity, ES migration is still the escalation path.

## Consequences

### Positive

- Formalizes what already happened in practice — Listing and Booking both use ES
- Full traceability across the money path (Space Catalog → Reservation → Payment)
- Uniform testing pattern (given/when/then on event streams) for all core modules
- New read models can be projected from existing events — no data migration scripts
- Decision axis (strategic classification) is clearer than complexity threshold (judgment call on
  "3+ rules")

### Negative

- Higher upfront cost for new core subdomains — decide/evolve/project/react + event store setup even
  for the first slice
- Event versioning becomes a cross-cutting concern as the system grows
- UserProfile ES adds infrastructure where CRUD would suffice for the data model alone — justified
  only by replay/audit value
- Discovery/Search as a projection consumer adds coupling to upstream event schemas

### Neutral

- Event store in `src/core/` is already load-bearing for Booking and Listing; Payment and
  UserProfile reuse the same port/adapter
- The 3+ business rules escalation threshold survives as a secondary signal for CRUD supporting
  subdomains

## Alternatives Considered

### Alternative 1: Keep CRUD Default with Complexity-Based Escalation

Rejected because it's already contradicted by practice. Both implemented core subdomains chose ES
independently. Maintaining CRUD-first as the documented default while building ES-first in practice
creates a doc-code divergence that misleads future contributors and agents.

### Alternative 2: Event Source Everything (All Subdomains)

Rejected per Greg Young's explicit guidance[^1] and Khononov's recommendation[^2]. IAM wraps
better-auth — ES on a third-party state wrapper is pure overhead. Notification is a stateless
delivery pipe. Review & Rating has no identified replay value yet. ES everywhere adds infrastructure
tax without business return for these contexts.

### Alternative 3: Event-Model Everything, Implement ES Selectively

Appealing in theory — every module gets event-modeled as a design artifact but only core subdomains
get ES runtime infrastructure. Rejected as unnecessary overhead for generic subdomains (IAM,
Notification) where event modeling the design provides no insight. Viable as a future refinement for
supporting subdomains approaching the complexity threshold.

## References

[^1]:
    Greg Young — "A Decade of DDD, CQRS, Event Sourcing" (DDD Europe 2016): "applying event sourcing
    everywhere is a really really bad idea… apply it selectively, only in a few places"

[^2]:
    Vlad Khononov — "Tackling Complexity in CQRS": "Event Sourcing is one of the most important
    tools in your toolbox. But as any tool, use it in its context — business domains that bring
    business value: Core Subdomains"

- Martin Fowler — [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
- Microsoft —
  [Event Sourcing Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing)
- Derek Comartin / Greg Young —
  [Greg Young Answers Your Event Sourcing Questions](https://codeopinion.com/greg-young-answers-your-event-sourcing-questions/)
- Project knowledge: [Event Modeling Pure Functions](event-modeling-pure-functions)
- Project knowledge: [CQRS Decision Framework](cqrs-decision-framework.md)
- Related: [ADR-0000](0000-classify-parko-subdomains-and-bounded-contexts.md),
  [ADR-0012](0012-use-state-level-switch-case-for-domain-function-fsms.md),
  [ADR-0014](0014-keep-domain-layer-null-free-using-adt-read-models.md)
