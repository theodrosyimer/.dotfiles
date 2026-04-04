# Aggregate Invariant Patterns

This reference helps dev__implement-feature by defining how to identify aggregates, classify invariant strength, and coordinate multi-aggregate operations.

## Aggregate Identification

The aggregate is NOT "the entity that performs the action." It is the entity that:
1. **Carries the invariant** (the business rule)
2. **Sits at the concurrency contention point** (where parallel requests collide)

```
WRONG: "Who performs the action?"
  -> "Client borrows book, so Client is the Aggregate"
  -> Leads to God Aggregates

RIGHT: "Who carries the invariant? Where is the contention?"
  -> "Only one borrower at a time" lives on the Book
  -> Concurrent requests for same book collide on Book
  -> Book is the Aggregate
```

## One Invariant = One Aggregate

Each distinct invariant maps to its own aggregate. Do NOT merge unrelated invariants into one aggregate (God Aggregate trap).

Example with two invariants:
- "A book can only be borrowed by one client" -> Book aggregate (contention on Book)
- "A client cannot have more than 5 borrows" -> Client aggregate (contention on Client)

## Strong vs Weak Invariants

This distinction determines the coordination strategy. Ask the business: "If this rule is briefly violated for 200ms before correction, is that acceptable?"

**Strong invariant** (absolutely inviolable):
- Physical impossibility or legal requirement
- No temporary violation acceptable
- Requires saga with reservation pattern
- Example: "A book MUST NOT be borrowed by two people simultaneously"

**Weak invariant** (temporarily violable):
- Brief violation has negligible business impact
- Eventual consistency + compensation is sufficient
- Example: "A client should not have more than 5 borrows"

## Coordination Patterns

### Weak Invariant: Eventual Consistency

```
1. Book.borrow(clientId)
   -> Check: book available? YES
   -> State change + optimistic lock
   -> Emit: BookBorrowed event

--- transaction boundary ---

2. Event handler: BookBorrowed
   -> Client.incrementBorrowCount()
   -> If count > 5: emit BorrowLimitExceeded
   -> Compensate: return extra borrow or flag for review
```

### Strong Invariant: Saga with Reservation

Reserve the **limiting resource first**, then attempt the action.

```
1. Client.reserveBorrowSlot()
   -> Verify: active borrows < 5?
   -> Mutate: increment counter
   -> Save: optimistic lock
   (All three atomic within Aggregate)

2. Book.borrow(clientId)
   -> Check: book available? YES
   -> State change + optimistic lock

3. IF Book.borrow() FAILS:
   -> COMPENSATE: Client.releaseBorrowSlot()
```

**Order matters**: Reserve limiting resource first, then act. Reversing the order widens the invariant violation window.

## The "Lying If" Anti-Pattern

`reserveBorrowSlot()` MUST verify + mutate + save atomically. A read-only check protects nothing:

```typescript
// BAD: "lying if" -- no protection
if (client.activeBorrows < 5) {
  book.borrow(clientId) // Two concurrent requests both pass this check
}

// GOOD: atomic verify + mutate + save
client.reserveBorrowSlot() // Throws if >= 5, increments + saves with optimistic lock
book.borrow(clientId)
```

The optimistic lock needs a **write** to detect conflicts. A check without a write gives the lock nothing to work with.

## Key Rules

1. Aggregate = invariant holder + concurrency contention point
2. One invariant = one aggregate (avoid God Aggregates)
3. Strong invariants need saga with reservation; weak invariants use eventual consistency
4. Reserve limiting resource first, then act
5. Verify + mutate + save must be atomic (no "lying if")
6. One aggregate per transaction (preferably)

## Sources

- Michael Azerhad, "DDD Aggregates -- Invariants, Concurrency, and Coordination"
