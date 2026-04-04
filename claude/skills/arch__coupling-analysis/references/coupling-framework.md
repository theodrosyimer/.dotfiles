# Coupling Analysis Framework

Self-contained reference for analyzing coupling across five dimensions. Derived from Michael Nygard's "Uncoupling" (GOTO 2018) and Udi Dahan's "How to Decouple Your Services" (NDC).

---

## Core Principle

Coupling is necessary — it enables systems to work together. The goal is not zero coupling but **choosing which dimensions matter** for your system's degrees of freedom. Every uncoupling strategy introduces a different kind of coupling. The engineering judgment is understanding the trade-offs.

Coupling behaves like mass-energy: you can transform it and move it around, but you cannot destroy it. Attempts to hide coupling (behind databases, entity services, or shared stores) usually make things worse by making it latent.

---

## Five Dimensions of Coupling

All five may be present simultaneously, in varying degrees. Each can be **visible** or **latent** (latent is always worse).

### 1. Operational Coupling

**Diagnostic**: Can system A function when system B is unavailable?

| Strength | Characteristics |
|----------|----------------|
| Strong   | Synchronous call — caller blocks or fails if provider is down (direct SQL, SMTP, synchronous HTTP) |
| Moderate | Caller degrades but continues — cached/stale data, fallback behavior |
| Weak     | Asynchronous via durable storage — caller publishes and moves on, consumer processes independently |

**Key detail**: SQL failover exceptions don't distinguish "retry, I just failed over" from "your query is bad, go away." REST failover is easier for clients. Message brokers allow the receiver to operate with stale data during outages.

### 2. Development-Time Coupling

**Diagnostic**: Does a change in B force a change in A?

| Strength | Characteristics |
|----------|----------------|
| Strong   | Shared database schema, direct code dependency — any internal change ripples (shared SQL tables, shared entities) |
| Moderate | API contract — some changes are absorbed, breaking changes still ripple (REST with typed DTOs) |
| Weak     | Multiple insulation layers — broker can translate formats, receiver can remap internally (pub/sub + extensible formats) |

**Key detail**: Well-established protocols (SMTP, HTTP) have weak development coupling despite strong semantic coupling — because they're unlikely to change. Stability of the contract matters as much as the contract's breadth.

### 3. Semantic Coupling

**Diagnostic**: Do A and B share vocabulary or concepts that could change?

| Strength | Characteristics |
|----------|----------------|
| Strong   | Shared domain model — both sides know about the same entities, attributes, relationships (shared ORM entities, full resource representations) |
| Moderate | Shared interface-layer model — concepts are mapped/flattened at the boundary (Gateway DTOs, API response shapes) |
| Weak     | Minimal shared vocabulary — only IDs and primitive values cross the boundary |

**Key detail**: GraphQL creates strong semantic coupling (consumers build knowledge of an object graph). REST at Richardson Level 5 also creates strong semantic coupling (consumers know everything about a resource). Both can be mitigated by ensuring the queryable schema is an interface layer, not direct domain exposure.

### 4. Functional Coupling

**Diagnostic**: Do A and B have overlapping responsibilities or implementations?

| Strength | Characteristics |
|----------|----------------|
| Strong   | Duplicated mechanisms — both components implement retry logic, reconnection handling, data transformation independently |
| Moderate | Partially shared — some common patterns but different enough to justify separation |
| Weak     | Distinct responsibilities — components do fundamentally different jobs |

**Key detail**: Moving to a message broker *increases* functional coupling — everyone deals with messages, broker connections, serialization. This is typically acceptable because functional coupling is easier to manage through shared libraries than operational or semantic coupling.

### 5. Incidental Coupling

**Diagnostic**: Could a change in A break B for no apparent causal reason?

| Strength | Characteristics |
|----------|----------------|
| Strong   | Shared implicit assumptions — hardcoded file paths, config keys, environment variables, database column names used by components that don't directly communicate |
| Moderate | Shared cross-cutting concerns — logging format, monitoring labels, shared infrastructure config |
| Weak     | No hidden shared assumptions — all coupling is explicit in code |

**Key detail**: Latent incidental coupling is "the absolute worst" — something breaks for no apparent reason and you don't understand why until after investigation. Two components that don't directly communicate but share implicit knowledge (file paths, queue names) are a classic source.

---

## Anti-Patterns to Detect

### Semantic Polymers

A concept from one system leaks through an entire chain of downstream systems, creating a long chain of semantic coupling.

**Detection**: An internal mechanism (price point, tier, workflow state) appears in DTOs or events consumed by systems that only need the *result* of that mechanism (a price, a status, a flag).

**Fix**: Flatten concepts at boundaries. If downstream needs a price, send a price — don't leak the price-point mechanism.

**Related insight (Nygard)**: "I don't need a SKU service — I need an identifier that lets me access different facets independently." Don't bundle everything into one entity just because a shared identifier exists. Separate attributes by which consumers actually need them.

### Long Arrows

A single arrow on a diagram hides a chain of operations (tables → files → network → files → tables → database swap). The entire chain inherits the **worst characteristics** of each step.

**Detection**: An integration that appears simple but involves multiple moving parts with different failure modes.

**Impact**: Latency ≥ slowest step. Availability ≤ least available link. Reliability ≤ least reliable step.

### Shared Database Coupling (Dahan)

Multiple components (including batch jobs) access the same tables without awareness of each other. Code coupling is at least traceable (set a breakpoint, follow the thread). Database coupling is invisible — you deploy, tests pass, and a batch job fails days later because it silently depended on the same data.

**Detection**: Two modules or slices reading/writing the same database tables. CRUD entity services wrapping a shared database (coupling is just hidden behind REST, not eliminated).

**Fix**: Each module/slice owns its data. Share via events carrying only IDs, not full entity payloads.

### Technology Cannot Fix Logical Coupling (Dahan)

If Component 1 calls `Foo(a, b, c, d)` on Component 2, replacing the in-process call with HTTP + gRPC + Protobuf changes nothing about the logical coupling. You still pass the same parameters, you still have the same dependency. If you cannot address the logical coupling, technology won't help. If you can, then technology (message brokers, events) amplifies the benefit.

**Detection**: A synchronous call between modules that was "decoupled" by adding an HTTP layer or message queue, but the payload and interaction pattern remain identical.

---

## Decision Matrix

For each dimension, the strategies that weaken it and what each strategy introduces as a trade-off.

### Operational Coupling → Weaken By:

| Strategy | Trade-off |
|----------|-----------|
| Invert flow: pub/sub via message broker | Eventual consistency, stale data |
| Cache/replicate data locally | Data freshness vs availability |
| REST over direct SQL | Still strong, but easier failover semantics |
| Circuit breaker + fallback behavior | Degraded experience, fallback logic complexity |

### Development Coupling → Weaken By:

| Strategy | Trade-off |
|----------|-----------|
| Functional interface (Parnas): hide storage/format decisions behind API | More modules, indirection |
| Add insulation layers (broker translates, receiver remaps) | Increased functional coupling (everyone deals with messages) |
| Extensible formats (JSON + open fields, tolerant reader) | Loose parsing, version drift |
| Gateway DTOs that flatten upstream concepts | Upstream must do more work to flatten before publishing |

### Semantic Coupling → Weaken By:

| Strategy | Trade-off |
|----------|-----------|
| Flatten concepts at boundaries (send price, not price-point) | Upstream must resolve/flatten before publishing |
| Shared interface library as "meeting point" between components | Shared library = coordination point for releases |
| Fewer, more general interfaces (Parnas: composability ∝ 1/interfaces) | Provider is more constrained (less you can assume) |
| Events carry only IDs, not full payloads (Dahan) | Consumer must look up data it needs independently |

### Functional Coupling → Weaken By:

| Strategy | Trade-off |
|----------|-----------|
| Extract shared functionality into library | Shared library = new coupling point (but localized) |
| Unify duplicate interfaces under one common abstraction | Requires agreement on common interface shape |

### Incidental Coupling → Weaken By:

| Strategy | Trade-off |
|----------|-----------|
| Encapsulate shared assumptions in a module (file paths, config) | More code to maintain |
| Make tacit coupling explicit in code | Forces you to find the hidden dependency first |
| Architectural tests that enforce dependency rules | Test maintenance, false positives on intentional coupling |

---

## Composability Principle (Parnas)

Composability is **inversely proportional** to the number of interfaces and data types. A smaller number of well-defined interfaces with a smaller number of data types is more composable.

**Strategy**:
1. Find interfaces doing the same thing with different names
2. Unify them into a common interface
3. Raise the level of abstraction
4. Multiple services implement the same interface

**Good abstraction test (Nygard)**: irreducibly simple, unifies dissimilar things by emphasizing shared properties. If your API starts expressing a general-purpose programming language, you've over-abstracted (inner platform effect).

---

## Orthogonality

Two concerns are orthogonal when changes along one axis have no effect along another — no "shadow" from one onto the other. This is the mathematical foundation of decision hiding: each module's internal decisions are orthogonal to other modules' concerns. High cohesion within each concern, low coupling between them.

**Practical strategy**: "Rotate the diagram 90 degrees." When looking at runtime components, think about the code modules. When looking at code, think about runtime structure. Solutions often live in the orthogonal view.

---

## Key Insight

Every uncoupling strategy introduces a different kind of coupling. Inverting flow to a message broker weakens operational coupling but increases functional coupling. Extracting a shared library reduces functional duplication but creates a coordination point. The goal is not zero coupling — it is choosing which dimensions matter most for your system's degrees of freedom, and accepting that some future changes will require degrees of freedom you didn't anticipate.

Prefer **explicit coupling over latent coupling**. If the coupling is going to be there but only exists in your head, find a way to write it down in the code and make it visible to whoever comes after you.
