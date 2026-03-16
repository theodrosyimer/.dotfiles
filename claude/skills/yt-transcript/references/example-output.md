# Event-Driven Architecture — Why In-Memory Event Bus Is a Bad Idea

> **Source**: Derek Comartin (CodeOpinion) — [YouTube](https://www.youtube.com/watch?v=KCvsk5tTP3w)
>
> **Core Argument**: The primary benefit of an in-memory event bus — shared process memory — is also its biggest drawback. Consumer failures cascade to producers, breaking the loose coupling that events are supposed to provide.

---

## 1. What Is an In-Memory Event Bus?

An in-memory event bus executes producers and consumers within the **same process**, using the **same memory**. Producers and consumers are still logically decoupled (the producer doesn't directly call consumers), but physically they share everything.

The primary use case where this is advocated is **domain events** — notifying other parts of your domain that something has occurred. This is because in-process execution lets consumers leverage the **same instance types** as the producer (most importantly, the same database transaction) through dependency injection.

When the producer publishes an event, the bus routes it to all registered consumers. Consumers can execute serially or in parallel, but regardless, control does **not** return to the producer until **all** consumers have finished.

```
IN-MEMORY EVENT BUS — Execution Flow

  Producer (Command Handler)
     │
     ├─ publishes "OrderPlaced" event
     │
     ▼
  ┌─────────────────────────────────────┐
  │         In-Memory Event Bus         │
  │  (MediatR, NestJS EventEmitter…)    │
  └─────────┬───────────────┬───────────┘
            │               │
            ▼               ▼
       Consumer A      Consumer B
    (Create Shipping)  (Send Email)
            │               │
            └───────┬───────┘
                    │
                    ▼
          Control returns to Producer
          ONLY after ALL consumers finish
```

In the .NET space, **MediatR** is the canonical example — it supports publishing "notifications" (which act like events) with everything done in-memory. Comartin demonstrates this with the **eShop on Web** sample application. The same pattern exists in Node.js with NestJS's built-in `EventEmitter`.

---

## 2. The Perceived Benefit: Shared Transactions

The main selling point is that consumers can implicitly share the producer's database transaction — and **the consumer doesn't even know it**. Through DI registration, the consumer receives the same DB context that the producer opened. It just executes its code as normal, makes state changes, completely unaware that it's wrapped in someone else's transaction.

```
SHARED TRANSACTION FLOW — In-Memory Bus

  1. Producer opens DB transaction
     ↓
  2. Producer makes state change (INSERT order)
     ↓
  3. Producer publishes event via in-memory bus
     ↓
  4. Consumer A executes → uses SAME transaction (unknowingly)
     ↓
  5. Consumer B executes → uses SAME transaction (unknowingly)
     ↓
  6. Transaction commits (all succeed) or rolls back (any failure)
```

This sounds appealing: everything succeeds or fails together as an atomic unit.

---

## 3. Why This Is Actually Harmful

### 3.1 The Core Problem: Failure Coupling

**You don't want everything generally to fail or succeed together.** The moment one consumer fails, the shared transaction rolls back **everything** — including the producer's original work and all other consumers' work. This destroys the isolation that pub/sub is supposed to provide.

In the eShop demo, two consumers listen to "OrderPlaced": one creates a shipping label via FedEx API, the other sends an email confirmation. When the FedEx call fails (network issue, API down), the entire order creation rolls back — no order, no shipping label, no email. Conversely, when the email service fails, the same thing happens: a perfectly valid order is lost because an email couldn't be sent.

### 3.2 Execution Order Ambiguity

Making things worse, **depending on the order of execution**, you may not even know which consumers ran before the failure. Did the email send before the shipping label failed? Maybe. Maybe not. The behavior depends on registration order, which is an implementation detail you shouldn't have to reason about.

### 3.3 The Naive Fix: Per-Consumer Retry Logic

The obvious reaction is to add retry logic (e.g., Polly in .NET). But this is insufficient for two reasons. First, you need to add retry policies to **every** consumer independently — adding Polly to the shipping consumer doesn't protect the email consumer. Second, even with retries, a consumer that exhausts its retries still rolls back the entire transaction, including the producer and every other consumer.

```
NAIVE FIX — Why Per-Consumer Retries Are Insufficient

  ❌ Adding Polly retry to Consumer A (shipping):
     → Shipping retries succeed after transient FedEx failure ✅
     → But email consumer has NO retry logic
     → Email failure still rolls back everything

  ❌ Adding Polly retry to BOTH consumers:
     → If retries exhaust, failure STILL cascades
     → You've added complexity without solving the fundamental problem
     → Each consumer needs its OWN strategy, not a shared one
```

### 3.4 The Business Argument

An email service being temporarily unavailable should **never** prevent an order from being placed. The business doesn't want to lose money or lose an order just because a confirmation email can't be sent. If the email arrives 3, 5, or 10 minutes later, that's perfectly acceptable — email is **naturally asynchronous**. It should not block order acceptance.

### 3.5 Developer Experience Degradation

The whole point of loose coupling is that you can add new consumers at will without worrying about existing ones. With an in-memory bus, every new consumer you add forces you to consider its impact on the producer and on every other consumer.

```
DEVELOPER EXPERIENCE — Adding New Consumers

  ❌ IN-MEMORY BUS:
     Adding Consumer C requires thinking about:
     - "What if C fails? Does it roll back A and B?"
     - "What retry logic does C need?"
     - "How does C's failure affect the producer?"
     - "What's the execution order? Does it matter?"
     → Each new consumer increases complexity for ALL consumers

  ✅ OUT-OF-PROCESS BUS:
     Adding Consumer C requires thinking about:
     - "What should C do when it receives the event?"
     - "What's C's own failure strategy?"
     → Each consumer is independent. No cross-consumer concerns.
```

**Each consumer, depending on what it does, should have a different strategy for handling failures.** A shipping label consumer might retry aggressively because FedEx is usually available. An email consumer might use exponential backoff because email services recover on their own. An analytics consumer might just drop the event after N failures. These strategies need to be **independent**, which is impossible when consumers share a transaction.

---

## 4. The Solution: Out-of-Process Event Handling

### 4.1 Decouple Execution, Not Necessarily Deployment

Moving event consumption out of process doesn't mean running a separate service. It means **separating publishers and consumers from executing together**. The event is persisted to durable storage and consumed independently — potentially by the **exact same process**, just not within the producer's request lifecycle.

```
OUT-OF-PROCESS EVENT FLOW

  1. Producer creates order + persists to DB
     ↓
  2. Producer publishes "OrderPlaced" to durable storage
     ↓
  3. Transaction commits → ORDER IS PLACED ✅ (done!)
     ↓
  ─── execution boundary ───
     ↓
  4. Same or different process picks event from storage
     ↓
  5. Consumer A executes independently
     │  ❌ fails → automatic retry by the library
     │  ✅ succeeds on retry
     ↓
  6. Consumer B executes independently
     │  ❌ fails → automatic retry by the library
     │  ✅ succeeds later
     ↓
  7. Each consumer succeeds or fails on its own terms
```

### 4.2 The Library Handles Retries

With a task queue or messaging library (Hangfire, BullMQ, RabbitMQ, etc.), **you don't have to write your own retry logic**. The library provides retries, configurable backoff, dead letter queues, and dashboards out of the box. Unlike the Polly approach where you manually wire retry policies per consumer, the infrastructure handles this for you.

### 4.3 Concrete Example: Hangfire

In the demo, Comartin replaces the in-memory MediatR approach with **Hangfire** — a task queue that provides external storage via Redis or SQL Server. After the change, orders are accepted successfully even when the email service is failing. The Hangfire dashboard shows the failing email job going through its default retry routine — completely independent of the order creation. The order is placed, the customer isn't lost, and the email will eventually succeed when the service recovers.

```
SAME PROCESS, OUT-OF-PROCESS EXECUTION

  ┌─────────────────────────────────────────────┐
  │              Single Process                  │
  │                                              │
  │  HTTP Request → Producer → DB + Event Store  │
  │       ↓                                      │
  │  Response sent immediately ✅                │
  │                                              │
  │  Background Worker (same process):           │
  │     picks up event from durable storage      │
  │     → Consumer A (independent, own retries)  │
  │     → Consumer B (independent, own retries)  │
  │     Library provides retry/backoff/dashboard  │
  └─────────────────────────────────────────────┘
```

---

## 5. Decision Framework

```
DECISION — When to use In-Memory vs Out-of-Process Event Bus

CONTEXT: Publishing domain events to notify other parts of the system

OPTION A: In-Memory Event Bus (e.g., MediatR notifications, NestJS EventEmitter)
  ✅ Zero infrastructure overhead
  ✅ Shared transaction scope (when genuinely needed)
  ✅ Simplest setup for prototyping
  ❌ Consumer failures cascade to producer (breaks loose coupling)
  ❌ Manual retry logic per consumer (Polly, etc.)
  ❌ Adding consumers increases system-wide risk
  ❌ Events lost on process crash
  ❌ Execution order ambiguity between consumers

OPTION B: Out-of-Process Event Bus (e.g., BullMQ, Hangfire, RabbitMQ, Redis Streams)
  ✅ True failure isolation per consumer
  ✅ Built-in retry, dead letter, backoff — no manual Polly needed
  ✅ Each consumer can have its own failure strategy
  ✅ Durable event delivery (survives crashes)
  ✅ Adding consumers is safe and independent
  ✅ Can still run in same process (not a separate deployment)
  ❌ Requires durable storage infrastructure (Redis, SQL, etc.)
  ❌ Eventual consistency (consumers execute later)

CHOSEN: Out-of-Process — because consumer independence is the entire
        point of pub/sub, and the infrastructure cost is minimal.
```

---

## 6. Relevance to Our Architecture

This aligns directly with our modular monolith approach and existing project knowledge on Udi Dahan's patterns.

```
APPLICATION TO MODULAR MONOLITH

INTER-MODULE EVENTS:
  ✅ Use durable event bus (BullMQ/Redis) for cross-module domain events
  ✅ Each module's consumers handle failures independently
  ✅ Each consumer defines its own failure/retry strategy
  ✅ Producer commits its transaction and moves on
  ✅ Same process, out-of-process execution via task queue

INTRA-MODULE (within a single use case):
  ✅ Direct method calls within the same use case are fine
  ❌ Don't use in-memory event bus to coordinate steps within one use case
     (that's just overcomplicating a synchronous workflow)

MIGRATION PATH:
  In-process event bus (dev/prototype)
     ↓
  Durable task queue, same process (modular monolith)
     ↓
  Message broker, separate processes (microservices)
```

### NestJS Implementation Direction

In our NestJS backend, prefer BullMQ (Redis-backed task queue) over the built-in `EventEmitter2` for domain events that trigger side effects like email, shipping, or notifications. The built-in emitter is an in-memory bus with all the problems described above.

```
PATTERN — Domain Event Publishing in Use Case

  ✅ GOOD — Persist event to durable queue:
     UseCase.execute()
       → persist order to DB
       → enqueue "OrderPlaced" to BullMQ
       → return success
     (consumers process independently via BullMQ workers)

  ❌ BAD — In-memory event bus:
     UseCase.execute()
       → persist order to DB
       → eventEmitter.emit("OrderPlaced")
       → all consumers execute in same request
       → any failure rolls back order
```

---

## Summary

The in-memory event bus gives you the **illusion of loose coupling** while maintaining tight coupling through shared transactions and execution context. The primary benefit — being in memory — is also the biggest drawback. Once you start leveraging the publish-subscribe pattern, you realize you don't want consumers to affect other consumers or the producer. You want them to be independent, each with its own failure strategy.

The fix isn't complex: persist events to durable storage and let consumers execute independently, even within the same process. You're just separating publishers and consumers from executing together. The messaging library handles retries, backoff, and monitoring — no manual Polly policies needed.

[^1]: Derek Comartin — [Don't Use an In-Memory Event Bus](https://www.youtube.com/watch?v=KCvsk5tTP3w)
