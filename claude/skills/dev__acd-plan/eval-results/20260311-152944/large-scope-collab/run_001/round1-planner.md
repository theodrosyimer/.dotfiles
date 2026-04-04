# Real-Time Collaboration for Canvas Editor

## Phase 1: Initial Framing

### User's Stated Outcome

"I need to add real-time collaboration to the canvas editor -- multiple users editing at once."

### Testable Hypothesis

> We believe **adding real-time multi-user editing to the ArchViz canvas** will result in **teams being able to collaboratively build and refine architecture visualizations without turn-taking or merge conflicts** because **architecture decisions are inherently collaborative, and forcing async handoffs (export/import JSON) creates friction that discourages adoption.**

### Scope Assessment: TOO LARGE -- Splitting Required

This request is an **epic**, not a single unit of work. "Real-time collaboration" spans at minimum:

1. **Networking layer** -- WebSocket/WebRTC server, connection management, reconnection
2. **Conflict resolution model** -- CRDTs, OT, or last-write-wins for concurrent edits
3. **Presence/awareness** -- Cursor positions, who-is-editing-what indicators
4. **Authentication/identity** -- Who is "User A" vs "User B"? Room/session model
5. **Persistence changes** -- Moving from local-only Dexie/localStorage to a shared data source
6. **UI indicators** -- Avatars, selection highlights, conflict toast notifications

Each of these is individually a multi-day effort. Specifying all six in one document would violate the ACD principle: "If your specification effort for a single change takes more than 15 minutes, the change is too large."

### Proposed Slices (ordered by dependency)

| # | Slice | Size | Dependency |
|---|-------|------|------------|
| 1 | **Shared data model + server sync** -- Replace local-only Dexie collections with a sync-capable backend (e.g., TanStack DB sync, or a lightweight WebSocket relay). Single-user first, proving the data round-trips. | Large | None |
| 2 | **Session/room model** -- Multiple clients connect to the same "project room" and receive each other's writes. No conflict resolution yet (last-write-wins at the record level). | Medium | Slice 1 |
| 3 | **Conflict resolution strategy** -- Choose and implement a merge strategy for concurrent edits to the same record (CRDT, field-level LWW, or operational transforms). | Large | Slice 2 |
| 4 | **Presence awareness** -- Broadcast cursor/selection state, show active user indicators in the UI (avatars, colored selections). | Medium | Slice 2 |
| 5 | **Auth + identity** -- Assign user identity (anonymous with display name, or OAuth). Gate room access. | Medium | Slice 2 |
| 6 | **Offline support + reconnection** -- Handle network drops gracefully, queue local changes, reconcile on reconnect. | Large | Slice 3 |

**Recommendation:** Spec Slice 1 first. It forces the hardest architectural decision (where does shared state live?) and everything else builds on top of it.

### Current Architecture Summary (from codebase exploration)

Key observations that constrain the collaboration design:

- **Purely client-side data today.** Collections live in Dexie (IndexedDB) and localStorage via `@tanstack/react-db`. The `container.ts` creates four collections: `config`, `structure`, `dataFlow`, `errors`. There is no server-side persistence or API for data mutation.

- **SSR via TanStack Start, but data is client-only.** The `_viz.tsx` route explicitly sets `ssr: false` and wraps everything in `DependenciesProvider`, which opens a client-side Dexie database. The server (`server.ts`) is a vanilla TanStack Start stream handler with no custom API routes.

- **Data is coarse-grained records.** Each collection stores a single large record (e.g., one `StructureRecord` containing the full tree). There is no fine-grained entity model -- edits replace the entire record. This is critical for conflict resolution: field-level merging on a deeply nested tree is fundamentally different from merging flat rows.

- **No user identity concept.** There is no auth, no user model, no session concept anywhere in the codebase. The app is a single-user local tool.

- **TanStack DB has sync primitives.** The `@tanstack/react-db` and `@tanstack/db` packages (v0.5.32) are being used. TanStack DB is designed with sync in mind (collections, live queries). This may provide built-in sync adapters or at minimum a clean interface for plugging one in.

- **Fixture-based seeding only.** Data enters the system via `loadDemoData()` in the layout, which calls seed functions that `insert()` into collections. The disabled menu items (Import JSON, Paste JSON, Connect repository) confirm that data input is still early-stage.

---

## Phase 2: Deep-Dive Interview

The following questions target implicit knowledge I cannot determine from the codebase alone. Each is high-signal for scoping the first slice.

### Question 1: What is the deployment/hosting model?

The current app is a TanStack Start SSR app with no backend API. Real-time collaboration requires a server component (at minimum a WebSocket relay, at maximum a full persistence layer).

- **Are you planning to self-host this, or target a serverless platform (Vercel, Cloudflare Workers)?** This determines whether a persistent WebSocket server is viable or whether you need a managed real-time service (e.g., PartyKit, Liveblocks, Supabase Realtime).
- **Is there an existing backend/database you want to use, or should this remain as self-contained as possible?**

*Why this matters:* The answer determines whether Slice 1 is "add a WebSocket server to the Start app" or "integrate a third-party sync service." These are radically different implementation paths.

### Question 2: What granularity of collaboration do you need?

Currently, each collection holds a single monolithic record (one `StructureRecord` with the full tree, one `DataFlowRecord` with all steps). Two users editing the same tree simultaneously will conflict at the record level.

- **Is it acceptable for collaboration to be "one editor per view tab at a time" (structure/data-flow/error-boundary), or do you need two people editing the same tree simultaneously?**
- **If simultaneous same-tree editing: should it be node-level locking (User A owns node X, User B owns node Y) or true concurrent editing (both edit the same node, merges happen automatically)?**

*Why this matters:* "One editor per tab" is achievable with record-level locking and is a 10x simpler first version. True concurrent tree editing requires CRDTs or OT on nested structures, which is a research-grade problem.

### Question 3: Does TanStack DB's sync story factor into your plans?

You are using `@tanstack/db` v0.5.32 with `@tanstack/react-db` and the Dexie adapter. TanStack DB appears to be designed with sync capabilities in mind (the collection abstraction, live queries, the separation of local-only vs persisted options).

- **Are you intentionally building on TanStack DB because you plan to use its sync/replication features when they mature?**
- **Or is TanStack DB a convenience choice, and you are open to replacing the data layer with something purpose-built for collaboration (e.g., Yjs, Automerge, Liveblocks)?**

*Why this matters:* If TanStack DB sync is the intended path, the first slice should align with its adapter model. If you are open to alternatives, a CRDT library like Yjs with a WebSocket provider could solve sync + conflict resolution in one package, but it means replacing the current data layer.

### Question 4: What is the editing model you envision?

The current app is read-only visualization. The menu has disabled "Import JSON" and "Paste JSON" buttons, and data entry is via `loadDemoData()`. The user mentioned "canvas editor" and "editing at once," which implies a future where users directly manipulate the visualization.

- **Does "editing" mean editing the raw JSON/schema data (like a structured form), or direct manipulation on the visual canvas (drag nodes, click to rename)?**
- **Does this editing capability already exist on a branch, or is it also something that needs to be built?**

*Why this matters:* If direct canvas editing does not exist yet, the collaboration feature depends on building the editing feature first. These are two separate epics and should be sequenced. You cannot collaborate on edits that cannot be made yet.

### Question 5: What is the target user count and latency tolerance?

- **How many simultaneous editors do you expect per project? 2-3 teammates, or potentially 10+?**
- **Is near-real-time (sub-second propagation) required, or is "eventual consistency within a few seconds" acceptable?**

*Why this matters:* 2-3 users with relaxed latency can use a simple relay server. 10+ users with sub-second updates requires a more sophisticated architecture (dedicated sync engine, delta compression, batched updates). This determines whether "simple WebSocket broadcast" is sufficient for the MVP.

---

## Summary and Recommendation

**This request is an epic containing at least 6 distinct slices.** The user should pick which slice to spec first.

My recommendation is to **start with Slice 1 (shared data model + server sync)** because:
1. It forces the foundational architectural decision (sync technology choice)
2. It can be validated with a single user (no collaboration UI needed yet)
3. Everything else depends on it

However, **Question 4 may reveal a blocker**: if the editing capability itself does not exist yet, the entire collaboration epic may need to be deferred until basic editing is functional. You cannot collaborate on a read-only visualization.

The answers to these five questions will determine:
- The technology stack for sync (TanStack DB native sync vs. Yjs/Automerge vs. managed service)
- The granularity target (record-level vs. node-level vs. field-level)
- Whether editing needs to be built first
- The infrastructure requirements (self-hosted server vs. third-party service)
