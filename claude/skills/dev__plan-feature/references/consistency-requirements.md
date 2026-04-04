# Reference: Consistency Requirements per Data Type

Use this reference during **Phase 1 (Feature Discovery)** and **Phase 2 (Complexity Assessment)** to classify the consistency requirements of data involved in the feature being planned.

**When to use:** Any feature that writes or reads data — which is all of them. The classification informs NFR decisions and, for CROSS_CONTEXT features, helps identify which contexts need strong vs eventual consistency.

---

## The Decision Question

For each data type the feature touches, ask:

> **"What is the business consequence of a user reading stale data?"**

---

## Classification Table

| Level | Label | Business Consequence | Consistency Level | Examples |
|-------|-------|---------------------|-------------------|----------|
| Critical | **STRONG** | Financial loss, safety risk, broken invariant | Linearizable / Serializable | Booking time slots, payment state, seat reservation, bank balance, medical records |
| Acceptable | **SESSION** | User confusion if they don't see own changes; others catching up is fine | Read-your-writes / Bounded staleness | User profile, space listing details, shopping cart, preferences |
| Negligible | **EVENTUAL** | 2-5s delay is invisible to users | Eventual consistency | Search results, activity feed, like counters, reviews, notifications, analytics |

---

## How to Apply During Planning

### In Phase 1 (Discovery) — Question 3: "WHAT data is involved?"

After listing inputs/outputs/transformations, tag each data type:

```
DATA TYPES:
  - Booking slot availability → STRONG (oversell = lost revenue + trust)
  - User profile updates → SESSION (user sees own edits immediately)
  - Search index → EVENTUAL (2-5s index lag invisible)
```

### In Phase 2 (Complexity Assessment)

STRONG data with cross-context dependencies is a signal for CROSS_CONTEXT complexity — it may require coordination patterns (saga, reservation slot) rather than simple event choreography.

### In Phase 6 (PRD Generation) — NFR Section

Map consistency classifications to non-functional requirements:

```json
{
  "nonFunctionalRequirements": [
    {
      "category": "scalability",
      "requirement": "Booking slot availability requires STRONG consistency — no overselling under concurrent access"
    },
    {
      "category": "performance",
      "requirement": "Search results may use EVENTUAL consistency — 2-5s index lag acceptable"
    }
  ]
}
```

---

## PACELC Quick Reference

CAP only applies during network partitions (rare). PACELC covers normal operation too:

```
IF partition → choose Availability or Consistency
ELSE (normal) → choose Latency or Consistency

  STRONG data → EC (consistent, accept latency cost)
  SESSION data → EL for reads, EC for own writes
  EVENTUAL data → EL (fast, accept staleness)
```

For Parko on single-node PostgreSQL, there's no CAP dilemma — only ACID + local concurrency. The PACELC "Else" trade-off still applies: CQRS commands (decide/evolve) pay the consistency cost; read models (project) serve fast, possibly stale data.

---

## Parko Data Type Map (Reference)

| Data Type | Consistency | Rationale |
|-----------|------------|-----------|
| Booking time slots | STRONG | Oversell = revenue loss + user trust |
| Payment state (escrow/split) | STRONG | Financial accuracy non-negotiable |
| User profile | SESSION | User sees own edits; others catch up |
| Space listing details | SESSION | Owner sees own changes immediately |
| Search/Discovery results | EVENTUAL | 2-5s index lag invisible |
| Reviews & Ratings | EVENTUAL | Not time-critical |
| Notifications | EVENTUAL | Delay is natural for async alerts |
| Activity feed / like counters | EVENTUAL | Lag is invisible |

---

## Key Distinctions

- **CAP Consistency ≠ ACID Consistency** — CAP-C = linearizability (all nodes see same data). ACID-C = business invariants maintained. Different concepts.
- **"Eventual" ≠ "wrong"** — data converges, it's just briefly stale. For most data types this is invisible.
- **One system, multiple levels** — different data in the same app deserves different guarantees. One-size-fits-all is always wrong.
- **Consistency is a business decision** — "what's the cost of stale data?" is a product question, not a database question.

> **Full reference**: See project knowledge doc `cap-theorem-consistency-availability-partition-tolerance.md` for complete educational content on CAP, PACELC, Kleppmann's delay-sensitivity framework, and the consistency spectrum.
