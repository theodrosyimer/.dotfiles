# Event Modeling Planning Checklist

This reference helps dev__plan-feature by extracting the event modeling steps relevant to feature planning: from event discovery through command/event identification to read model design.

## Planning Sequence

### Step 1: Capture Business Narrative as Events
- Events are orange sticky notes, verb phrases in past tense (e.g., "Ride Scheduled")
- Each event has a name/type and a data payload
- Events must be denormalized and data-covering (all data inline, except large blobs via claim check pattern)
- Brainstorm events (~15 min) then sequence and filter (~10 min)

**What is NOT an event:**
- Low-level UI/system events (mouse clicks, TCP packets)
- Queries, views, or state notifications (these are read models)
- User requests to change state (these are commands)

### Step 2: Envision User Experience
- Place interface mockups above corresponding events
- Organize audiences into horizontal lanes
- This surfaces: "Where does this UI get its data?" (read models) and "What happens on submit?" (commands)

### Step 3: Identify Commands and Read Models
- **Command** (blue sticky, imperative verb): User's expression of intent to change state
  - Speculative and untrusted
  - Handled synchronously (transactional moment)
  - Triggers validation via `decide` function
- **Read Model** (green sticky, noun phrase): View into system state at a point in time
  - Created/updated by event arrival
  - Built by `evolve`/`project` functions
  - Can use any persistence (relational, key-value, search index)

### Step 4: Identify Event Streams
- Each stream = a mostly independent causal narrative = a bounded context
- Streams must be self-sufficient (full history of state changes)
- Foreign events translated/copied into local stream, not merely observed

## The Four Slice Types

Every feature decomposes into these implementation units:

| Slice Type | Flow | Example |
|-----------|------|---------|
| State Change | Interface -> Command -> Event | User clicks "Book" -> BookingRequested |
| State View | Event -> Read Model -> Interface | BookingConfirmed -> Booking Details page |
| External Import | Foreign Event -> react -> Local Command -> Local Event | PaymentReceived -> ConfirmBooking |
| Internal Export | Local Event/Read Model -> exposed to other streams | BookingConfirmed consumed by Notification stream |

## Inter-Stream Integration Patterns

### Pattern A: Saga / Stateless Reaction
Foreign event triggers local command via `react` function.
```
Foreign: "Ride Scheduled" --react--> Local: "Mark Vehicle Occupied" command
```

### Pattern B: Job Interface (To-Do List)
Foreign read model populates local to-do list. Automated job processes items.
```
Available Vehicles + Rides To Schedule --> Scheduler Job --> "Schedule Ride" command
```

### Pattern C: Invoking Foreign Commands
Local stream invokes foreign command and records local event of result.
Common with third-party services (payment processors).

## The Four Domain Functions

| Function | Signature | Purpose |
|----------|-----------|---------|
| `decide` | (command, state) -> events | Validate command against current state, produce events |
| `evolve` | (state, event) -> new state | Rebuild write-side aggregate state from events |
| `project` | (events) -> read model | Build read-side projections from event stream |
| `react` | (event) -> side effects | Trigger cross-stream commands or notifications |

## Feature Planning Checklist

For each feature being planned:

- [ ] What events does this feature produce? (past tense verb phrases)
- [ ] What commands trigger those events? (imperative verb phrases)
- [ ] What read models does the UI need? (noun phrases)
- [ ] Which event stream does this belong to?
- [ ] Does this feature need data from other streams? (integration pattern)
- [ ] What are the command validation rules? (`decide` function logic)
- [ ] What state does the `decide` function need? (which events to replay)
- [ ] CQRS classification: CRUD, CQRS, or CROSS_CONTEXT?
