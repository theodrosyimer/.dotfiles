# 0000. Classify Parko Subdomains and Bounded Contexts

**Date**: 2026-03-03

**Status**: accepted

**Deciders**: Theo <!-- project extension, not in Nygard's original -->

**Confidence**: high — domain analysis stabilized through frontend-first development and multiple
module implementations

**Reevaluation triggers**: New revenue model requiring a subdomain not covered here; user research
revealing a Supporting context is actually a competitive differentiator; merger/acquisition adding
an entirely new product vertical.

## Context

Parko is a peer-to-peer space rental marketplace (parking and other space types). The project is at
an early stage with foundational modules (IAM, UserProfile, Listing) partially implemented and core
transactional features (Booking, Payment) on the roadmap.

Without a clear strategic domain map, there is a high risk of:

- Entity-centric modules (the "User" god-module anti-pattern already encountered and being
  refactored — see IAM/UserProfile split)
- Misplaced business logic (e.g., reviews stored in User module, availability owned by the wrong
  context)
- Ambiguous module boundaries as new features are added
- Difficulty prioritizing implementation order

The platform has confirmed requirements for time-slot-based availability, escrow/split payments, and
host-renter messaging — all of which influence where bounded context boundaries should fall.

This decision builds on DDD strategic design principles (Evans, Fowler, Vernon) and the project's
modular monolith architecture.

## Decision

**We will classify Parko's domain into the following subdomains and bounded contexts, organized by
strategic importance.**

### CORE — Competitive Advantage

Custom-built, highest investment, no off-the-shelf replacement.

| Subdomain         | Bounded Context | Ubiquitous Language                                                                                                                 | Why Core                                                                                                                |
| ----------------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **Space Catalog** | Listing         | listing, space type, dimensions, pricing rules, photos, publish, draft, availability, calendar, time slot, blackout dates, schedule | The _product_ being offered — how hosts describe and price their spaces, including the availability windows they define |
| **Reservation**   | Booking         | booking, time slot, availability, check-in, check-out, cancellation policy, extension                                               | The transactional heart — matching renters to available spaces in time                                                  |
| **Discovery**     | Search          | nearby, filter, ranking, geolocation, availability window                                                                           | How renters _find_ the right space — differentiator over competitors                                                    |

**Listing vs Booking boundary**: Availability/calendar lives at the intersection. Listing owns the
_definition_ of available slots (host sets schedule). Booking owns the _consumption_ of slots
(renter reserves). Communication via Gateway pattern — Booking calls
`SpaceListingGateway.getSpaceAvailability()`.

### SUPPORTING — Business-Specific but Not Differentiating

Necessary for the platform to function. Contains Parko-specific business rules but isn't the
competitive moat.

| Subdomain                 | Bounded Context | Ubiquitous Language                                                | Key Complexity                                                                                                                                                                              |
| ------------------------- | --------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Payment Orchestration** | Payment         | escrow, split payment, platform fee, host payout, refund           | Split payments (platform cut vs host payout), escrow (hold until check-out), refund policies tied to cancellation rules. Stripe handles plumbing — this context owns _when/how_ money moves |
| **User Profile**          | UserProfile     | host profile, renter profile, bio, rating, reputation, preferences | Role-specific views (host vs renter), aggregate reputation scores. ES justified for customer support replay and GDPR audit trail (ADR-0009)                                                 |
| **Review & Rating**       | Review          | review, rating, feedback, aggregate score                          | Post-booking outcome. Bridges Booking (triggers review), Listing (aggregate rating), UserProfile (reviewer reputation). Consider co-locating with Booking initially                         |
| **Messaging**             | Messaging       | conversation, message, thread, participant                         | Host-renter communication: pre-booking questions, coordination. Supporting because it enables transactions but isn't the transaction itself                                                 |

### GENERIC — Commodity, Off-the-Shelf

Buy or wrap existing solutions. Minimal custom business logic.

| Subdomain                 | Bounded Context | Implementation                     | Notes                                                                                                                                                                                            |
| ------------------------- | --------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Identity & Access**     | IAM             | better-auth wrapper                | Thin gateway: `IamGateway.getCurrentIdentity(session)` → `IdentityDto`. No repository, no use cases. better-auth owns the tables                                                                 |
| **Notification Delivery** | Notification    | Resend (email), Expo Push (mobile) | Dumb pipe — receives events, delivers messages. The _decision_ of what/when to notify is owned by each domain context (Booking publishes `BookingConfirmedEvent`, Notification handles delivery) |

### Context Map

```
                    ┌─────────────┐
                    │     IAM     │ (Generic)
                    │ better-auth │
                    └──────┬──────┘
                           │ IdentityDto
                    ┌──────▼──────┐
              ┌─────┤ UserProfile │◄────────┐
              │     └─────────────┘         │
              │      (Supporting)           │ reviewer info
              │                             │
     ┌────────▼────────-┐          ┌────────┴───────-┐
     │  Space Catalog   │◄─────────┤    Review       │
     │   (Listing)      │ agg.     │                 │
     │                  │ rating   └────────▲────────┘
     └────────┬─────────┘                   │ post-booking
              │                             │
              │ Gateway:                    │
              │ getSpaceAvailability()      │
              │                   ┌──-──────┴────────┐
     ┌────────▼────────┐          │    Reservation   │
     │    Discovery    │◄─────────┤     (Booking)    │
     │    (Search)     │ read     │                  │
     └─────────────────┘ model    └───────┬──────────┘
                                          │
                                          │ BookingConfirmedEvent
                                          │ CancellationEvent
                                  ┌───────▼──────────┐
                                  │     Payment      │
                                  │  Orchestration   │
                                  └───────┬──────────┘
                                          │
                                          │ events
                                  ┌───────▼──────────┐
                                  │   Notification   │ (Generic)
                                  └──────────────────┘
```

### Implementation Priority

| Phase       | Context                   | Rationale                                                                                                                                                             |
| ----------- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Now**     | IAM, UserProfile, Listing | Foundation — can't do anything without identity and spaces to list                                                                                                    |
| **Next**    | Booking, Payment          | Core transaction loop — renter can reserve and pay                                                                                                                    |
| **Then**    | Discovery (Search)        | Read-optimized query model over listings. Until then, basic list/filter is enough                                                                                     |
| **Later**   | Review                    | Post-MVP — builds trust but platform works without it. Co-locate with Booking initially                                                                               |
| **Later**   | Messaging                 | Post-MVP — needed for longer-term rentals (storage, garages) where renters ask questions before booking. Watch for early user signals. Hourly parking doesn't need it |
| **Ongoing** | Notification              | Evolves incrementally as each context adds events                                                                                                                     |

### Architectural Complexity per Context

```
EVENT SOURCED (decide/evolve/project/react) — ADR-0009:
  ✅ Listing — core subdomain, state machine (registered → available ↔ occupied → delisted),
     cross-stream integration with Booking via react
  ✅ Booking — multi-step workflow, state machine (pending → confirmed → started →
     completed → cancelled), event-driven side effects
  ✅ Payment — escrow lifecycle, split logic, refund replay, audit trail
  ✅ UserProfile — customer support replay, GDPR audit trail (supporting with
     concrete replay value)

PROJECTION CONSUMER (read model over upstream event streams):
  ✅ Discovery/Search — geo-indexed, availability-filtered query model projected
     from Listing + Booking events. PostGIS initially, Elasticsearch later if needed

SIMPLE CRUD (no ES, no CQRS):
  ✅ Review & Rating — post-booking feedback, aggregate scores. Re-evaluate post-MVP
  ✅ Messaging — CRUD or third-party wrapper. Re-evaluate post-MVP

WRAPPER (no domain logic):
  ✅ IAM — better-auth owns state, thin gateway only
  ✅ Notification — stateless delivery pipe, event consumer only
```

### Ubiquitous Language Boundaries

Each context has its own meaning for shared terms:

| Term             | In Listing                                       | In Booking                                   | In Payment                         |
| ---------------- | ------------------------------------------------ | -------------------------------------------- | ---------------------------------- |
| **Space**        | A product with dimensions, photos, pricing rules | A reference ID to check availability against | Not relevant                       |
| **Price**        | Base hourly/daily rate set by host               | Calculated total for a booking period        | Amount to charge, split, or refund |
| **User**         | Host (the owner)                                 | Renter (the customer) or Host (the provider) | Payer or Payee                     |
| **Availability** | Calendar of open time slots defined by host      | Whether a slot is free for reservation       | Not relevant                       |
| **Cancellation** | Not relevant                                     | A state transition with policy rules         | Triggers refund calculation        |

## Consequences

### Positive

- Clear ownership boundaries prevent the god-module anti-pattern (no more "User" module absorbing
  everything)
- Each context can evolve independently with the architectural complexity appropriate to its
  strategic classification
- Implementation priority is explicit — team knows what to build next and why
- Gateway/ACL communication pattern prevents context coupling
- Ubiquitous language table eliminates ambiguity when modeling shared concepts

### Negative

- 10 bounded contexts is a lot for an early-stage project with a small team — risk of
  over-engineering module boundaries before the domain is fully understood
- Some contexts (Review, Messaging) may be premature to formalize — they could start as features
  within Booking before earning their own boundary
- Discovery as a separate read model adds infrastructure complexity (PostGIS, eventually
  Elasticsearch) that may not be justified until scale demands it

### Neutral

- Payment classified as Supporting (not Generic) means custom orchestration logic — more work than a
  pure Stripe wrapper, but necessary for escrow/split requirements
- Notification as Generic means each context owns its own event publishing — distributed
  responsibility for "when to notify"

## Alternatives Considered

### Alternative 1: Fewer Contexts — Merge Listing + Discovery + Review

Combine into a single "Spaces" bounded context. Rejected because:

- Listing (write) and Discovery (read) have fundamentally different optimization needs and data
  models
- Review is a booking outcome, not a listing attribute — mixing them creates the same entity-centric
  coupling that caused the User module problem

### Alternative 2: Payment as Generic

Treat Payment as a thin Stripe wrapper. Rejected because:

- Escrow, split payments, and refund policies tied to cancellation rules are Parko-specific business
  logic
- The _plumbing_ (Stripe API calls) is generic; the _orchestration_ (when to charge, hold, release,
  split) is business logic

### Alternative 3: No Messaging Context — Use Third-Party Chat

Outsource messaging entirely (e.g., Stream, Sendbird). Still viable — but if messaging needs to
integrate with booking state (e.g., auto-message on booking confirmation, pre-booking Q&A linked to
listing), a thin internal context wrapping the third-party service is preferable.

## References

- Eric Evans — _Domain-Driven Design: Tackling Complexity in the Heart of Software_
- Vaughn Vernon — _Implementing Domain-Driven Design_ (Identity & Access context pattern)
- Martin Fowler — [Bounded Context](https://martinfowler.com/bliki/BoundedContext.html)
- Project knowledge: `Domains_vs_Bounded_Contexts_in_DDD`
- Project knowledge: `Modular_Monoliths_with_Vertical_Slices_Gateway_and_ACL_Patterns.md`
- Related: [ADR-0009](0009-event-source-core-subdomains-by-default.md)
- Prior conversation:
  [Refactoring User module to IAM bounded context](https://claude.ai/chat/02857585-59d7-4df5-968e-59c252429977)
