# Slice 1: Backend Sync for Single-User Local-First Persistence

## Intent

**Problem:** ArchViz is purely client-side. All data (config, structure, dataFlow, errors) lives in Dexie/IndexedDB and localStorage with no server persistence. Users cannot access their architecture visualizations from another device, and there is no foundation for future multi-user collaboration. If the browser storage is cleared, all work is lost.

**Desired outcome:** A single user's local edits persist to a Node.js backend and rehydrate on any device where that user authenticates. The app remains fully functional offline; edits made offline sync to the server upon reconnection. This slice establishes the server, data model, transport, and sync protocol that later slices (rooms, presence, multi-user conflict resolution) will build on.

**Rationale:** Without a server-side persistence layer, there is no path to collaboration. This slice delivers immediate value (cross-device access, durable storage) while laying the infrastructure foundation. Keeping it single-user-scoped avoids premature complexity around conflict resolution and presence.

**Hypothesis:** We believe adding server-backed sync with offline support will result in users retaining their architecture visualizations across devices and browser clears, because the current IndexedDB-only storage makes data loss a single cache-clear away, and cross-device access is impossible.

---

## User-Facing Behavior

### Scenario: First load with empty server state
```
Given a user opens ArchViz for the first time on a new device
  And the server has no records for this user
When the app finishes loading
Then the local Dexie database is empty (no stale data from another user)
  And the app behaves identically to today (seed data can be inserted locally)
  And those seed records sync to the server within 5 seconds
```

### Scenario: Returning user on a new device
```
Given a user has previously created architecture data on Device A
  And that data has synced to the server
When the user opens ArchViz on Device B and authenticates
Then all four collections (config, structure, dataFlow, errors) populate from the server
  And the visualizations render identically to Device A
```

### Scenario: Editing while online
```
Given the user is connected to the server
When the user inserts, updates, or deletes a record in any collection
Then the mutation is applied locally immediately (optimistic)
  And the mutation is sent to the server
  And the server persists it and responds with confirmation
  And if the server rejects the mutation (validation failure), the local optimistic state rolls back
```

### Scenario: Editing while offline
```
Given the user has lost network connectivity
When the user inserts, updates, or deletes records
Then mutations apply locally and the app remains fully functional
  And mutations queue in a persistent outbox (survives page reload)
```

### Scenario: Reconnection after offline edits
```
Given the user made edits while offline
  And the outbox contains pending mutations
When network connectivity is restored
Then queued mutations replay to the server in order
  And the server applies them using last-write-wins per record (keyed on record id + _updatedAt timestamp)
  And if the server has a newer version of a record, the server version wins
  And the local state updates to reflect the server's authoritative version
```

### Scenario: Server unreachable during initial load
```
Given the user opens the app but the server is unreachable
When Dexie has locally cached data from a prior session
Then the app loads from the local cache and operates in offline mode
  And a non-blocking indicator shows "offline" status
```

### Scenario: Server unreachable on first-ever load
```
Given the user opens the app for the first time (empty Dexie)
  And the server is unreachable
When the app finishes loading
Then the app loads with an empty state (same as current behavior)
  And the user can create data locally
  And sync begins automatically when connectivity is established
```

---

## Feature Description

### Musts

- **Local-first architecture:** All reads come from Dexie/IndexedDB. The server is the sync target, not the read path. The app must never block on a server response to render UI.
- **Four collections synced:** `config`, `structure`, `dataFlow`, `errors` -- all four collection types defined in `src/schemas/*.schema.ts` must sync.
- **Record-level granularity:** Each record (identified by its `id` field) is the unit of sync. No field-level diffing.
- **Last-write-wins conflict resolution:** When the server receives a mutation for a record that has been modified since the client last saw it, the write with the later `_updatedAt` timestamp wins. No merge logic.
- **Persistent outbox:** Offline mutations must survive page reloads. Store the outbox in IndexedDB (Dexie).
- **Server stack:** Node.js runtime. PostgreSQL or SQLite for persistence (implementer's choice, but must support the four collection schemas). Deployed to Railway or Fly.io.
- **Transport:** WebSocket for real-time push from server to client. HTTP fallback for initial sync and mutation submission if WebSocket is unavailable.
- **Schema validation on server:** All incoming records must be validated against the same Zod schemas used client-side (`configSchema`, `structureSchema`, `dataFlowSchema`, `errorsSchema`). Share the schema files between client and server (monorepo or shared package).
- **Timestamps:** Every record must carry `_updatedAt` and `_createdAt` fields (ISO 8601 strings or epoch milliseconds). These are set by the server on write, not trusted from the client (server is the clock authority for conflict resolution).
- **TanStack DB integration:** Use TanStack DB's `Collection` and its existing `startSync`, `PendingMutation`, and optimistic mutation patterns where possible. If TanStack DB does not provide a built-in sync adapter for this use case, implement a custom collection options factory (similar to `dexieCollectionOptions`) that wraps Dexie for local storage and adds server sync.
- **Connection status:** Expose a reactive connection status (`connected`, `connecting`, `disconnected`) via the existing DI container (`Container` interface in `src/collections/container.ts`).
- **UUID v7 keys:** Continue using `uuid` v7 for record IDs (already in use via `src/infrastructure/seeders/seed.ts`).
- **No auth in this slice:** Authentication (GitHub OAuth) is deferred to Slice 5. This slice operates with a single implicit user. The server accepts all connections without authentication. The data model should include a `userId` field on records so auth can be added later without a migration, but it is not enforced in this slice.

### Must Nots

- **Must not break offline usage:** If the server is down or unreachable, the app must work exactly as it does today (local-only mode).
- **Must not introduce user-visible latency:** Reads must never wait for the server. Mutations must apply optimistically before the server responds.
- **Must not change existing Zod schemas structurally:** The four schemas in `src/schemas/` define the domain model. Sync metadata (`_updatedAt`, `_createdAt`, `userId`) must be added as extensions/wrappers, not by modifying the core schemas.
- **Must not implement multi-user features:** No rooms, no presence, no multi-user conflict resolution beyond last-write-wins. This is single-user sync.
- **Must not deploy auth middleware:** No login flow, no OAuth, no tokens. That is Slice 5.
- **Must not require a specific cloud provider's proprietary services:** Use standard Node.js, standard PostgreSQL/SQLite, standard WebSockets. No Firebase, Supabase, or proprietary sync services.

### Preferences

- Prefer SQLite (via `better-sqlite3` or `libsql`) for the server database to minimize deployment complexity. PostgreSQL is acceptable if the implementer has a strong reason.
- Prefer a monorepo structure (server code in a `server/` directory at the project root) over a separate repository.
- Prefer the WebSocket library `ws` (Node.js) over Socket.IO to keep the dependency surface small.
- Prefer sending full records over the wire (not diffs) since records are small and record-level granularity is specified.
- Prefer wrapping the sync logic in a custom TanStack DB collection options factory (e.g., `syncedDexieCollectionOptions()`) so the `container.ts` wiring changes minimally.
- Prefer a single WebSocket connection multiplexed across all four collections over four separate connections.

### Escalation Triggers

- **TanStack DB sync primitives are insufficient or undocumented:** If TanStack DB's `PendingMutation` / `startSync` / optimistic action patterns do not support the offline outbox + server reconciliation pattern described here, escalate before building a custom sync engine from scratch. The user may want to reconsider the approach or accept a simpler sync model.
- **Schema sharing between client and server is blocked:** If the Zod v4 schemas cannot be imported in a Node.js server context (e.g., due to browser-only dependencies in the import chain), escalate before duplicating schemas.
- **Record size exceeds 1MB:** If any single record in the four collections exceeds 1MB when serialized to JSON, escalate. The sync protocol assumes small records.
- **Dexie version conflict:** If adding sync metadata fields to Dexie requires a database version migration that breaks existing local data, escalate with a migration strategy before proceeding.

---

## Acceptance Criteria

### Done Definition

- [ ] A Node.js server process starts and listens for WebSocket connections on a configurable port.
- [ ] The server exposes an HTTP endpoint (`GET /health`) that returns `200 OK` with `{"status": "ok"}`.
- [ ] The server persists records for all four collections (config, structure, dataFlow, errors) in a database.
- [ ] The client, on load, connects to the server via WebSocket and receives all existing records for the four collections.
- [ ] Records received from the server are inserted into the local Dexie database and appear in TanStack DB collections.
- [ ] When the client inserts a record locally, the mutation is sent to the server via WebSocket and persisted server-side.
- [ ] When the client updates a record locally, the updated record is sent to the server and persisted.
- [ ] When the client deletes a record locally, the deletion is sent to the server and the record is marked as deleted (soft delete) or removed.
- [ ] When the client is offline, mutations are queued in a Dexie-backed outbox.
- [ ] When the client reconnects, queued mutations are sent to the server in order.
- [ ] The server applies last-write-wins: if a mutation arrives for a record whose server-side `_updatedAt` is newer, the server's version is retained and the client is notified to update its local copy.
- [ ] The app loads and renders from local Dexie data without waiting for the server (local-first).
- [ ] A connection status indicator is available in the UI (can be a minimal text badge; styling is not the focus).
- [ ] The existing Zod schemas are importable and used for validation on both client and server without duplication.
- [ ] All existing tests pass (`vitest run`).
- [ ] A new test suite covers: server startup, record CRUD over WebSocket, offline queueing, reconnection replay, last-write-wins resolution.

### Test Cases

| # | Input | Expected Output | Notes |
|---|-------|----------------|-------|
| 1 | Client sends `{ type: "insert", collection: "structure", record: {id: "abc", ...validStructure} }` via WebSocket | Server persists the record and responds `{ type: "ack", mutationId: "...", record: {...} }` with server-assigned `_updatedAt` | Happy path insert |
| 2 | Client sends `{ type: "insert", collection: "structure", record: {id: "abc", left: null} }` (invalid per schema) | Server responds `{ type: "reject", mutationId: "...", error: "Validation failed: ..." }` and does not persist | Schema validation on server |
| 3 | Client sends an update for record "abc" with `_updatedAt: T1`, but server has `_updatedAt: T2` where `T2 > T1` | Server responds `{ type: "conflict", mutationId: "...", serverRecord: {...} }`. Client replaces local record with server version. | Last-write-wins |
| 4 | Client sends an update for record "abc" with `_updatedAt: T2`, server has `_updatedAt: T1` where `T1 < T2` | Server accepts the update, persists it, responds with `ack` | Client wins when newer |
| 5 | Client goes offline, inserts record "def", updates record "ghi" | Both mutations are stored in the Dexie outbox. App continues to function with the optimistic local state. | Outbox persistence |
| 6 | Client reconnects after test 5 | Outbox mutations are sent to server in insertion order. Server processes and responds with acks/conflicts. Outbox is cleared after successful processing. | Reconnection replay |
| 7 | Client loads with empty Dexie, connects to server that has 3 structure records | After sync, Dexie contains 3 structure records. TanStack DB collection queries return them. | Initial hydration |
| 8 | Client loads with populated Dexie, server is unreachable | App renders from Dexie data. Connection status shows "disconnected". All local operations work. | Offline-first resilience |
| 9 | Server restarts while client is connected | Client detects disconnect, shows "disconnected" status, queues mutations in outbox. On server recovery, client reconnects and replays outbox. | Server crash recovery |
| 10 | Two browser tabs open simultaneously (same user) | Both tabs connect via separate WebSockets. Mutations from tab A appear in tab B after server round-trip. (Dexie's existing cross-tab sync via `BroadcastChannel` may also propagate locally.) | Multi-tab consistency |

---

## Task Decomposition

This slice exceeds 2 hours of implementation. It breaks into the following sub-tasks:

### Task 1: Server scaffold and health endpoint (Small)
**Inputs:** None
**Outputs:** A `server/` directory at the project root with a Node.js entry point, `package.json`, and TypeScript config. `GET /health` returns `200 OK`.
**Boundary:** Server-side only. No client changes.
**Acceptance:** Server starts, health endpoint responds, `vitest` or equivalent server test validates it.

### Task 2: Server database and collection persistence (Medium)
**Inputs:** Zod schemas from `src/schemas/`, server scaffold from Task 1.
**Outputs:** Database tables/collections for config, structure, dataFlow, errors. CRUD functions that validate against Zod schemas. `_updatedAt`, `_createdAt`, `userId` columns on every table.
**Boundary:** Server-side only. Database layer with unit tests.
**Acceptance:** Tests insert, read, update, soft-delete records. Schema validation rejects invalid records.
**Depends on:** Task 1.

### Task 3: WebSocket server with sync protocol (Medium)
**Inputs:** Server database from Task 2.
**Outputs:** WebSocket endpoint on the server that accepts connections, receives mutations (`insert`, `update`, `delete`), persists them, and broadcasts changes. Protocol messages defined as TypeScript types. Last-write-wins logic implemented.
**Boundary:** Server-side only. Protocol type definitions shared.
**Acceptance:** Test cases 1-4 from the table above pass.
**Depends on:** Task 2.

### Task 4: Client sync adapter with outbox (Large)
**Inputs:** WebSocket protocol from Task 3, existing `container.ts` and `dexieCollectionOptions`.
**Outputs:** A `syncedDexieCollectionOptions()` factory that wraps Dexie persistence with WebSocket sync. Outbox table in Dexie for offline mutations. Reconnection logic with outbox replay. Connection status exposed on the `Container`.
**Boundary:** Client-side. Modifies `container.ts` and `context.tsx`. Adds new files in `src/collections/` or `src/infrastructure/`.
**Acceptance:** Test cases 5-9 from the table above pass. Existing app behavior unchanged when server is unreachable.
**Depends on:** Task 3.

### Task 5: Connection status UI indicator (Small)
**Inputs:** Connection status from Task 4's `Container`.
**Outputs:** A minimal status badge in the layout (connected/connecting/disconnected). Non-blocking, informational only.
**Boundary:** UI only. Single component in `src/views/layout/` or `src/shared/components/`.
**Acceptance:** Badge reflects actual connection state. Does not block any user interaction.
**Depends on:** Task 4.

### Task 6: Integration tests and multi-tab verification (Small)
**Inputs:** All prior tasks.
**Outputs:** End-to-end test suite covering test cases 7-10. Verifies full sync loop: client insert -> server persist -> second client receives.
**Boundary:** Test files only.
**Acceptance:** All 10 test cases from the table above pass.
**Depends on:** Tasks 4, 5.

---

## Stress-Test Review

### Issues found and resolved inline:

1. **Vague: "sync within 5 seconds"** -- The first scenario said "within 5 seconds." This is a soft target for user perception, not a hard SLA. Kept as-is because it communicates intent; the test case does not enforce a specific timeout but verifies that sync completes.

2. **Missing: soft delete vs hard delete** -- The acceptance criteria now explicitly call out that deletions can be either soft-delete (tombstone) or hard-delete, as long as the client is notified. The implementer should choose soft-delete to support offline reconciliation (a hard-deleted record cannot be detected as "deleted" by a reconnecting client). Resolved: Test case table says "marked as deleted (soft delete) or removed" -- leaving implementer choice but flagging the trade-off.

3. **Missing: initial sync protocol** -- How does the client know what records exist on the server on first connect? Added Scenario "Returning user on a new device" and Test Case 7 to cover initial hydration. The protocol should include an initial `sync` message type where the server sends all records for all collections.

4. **Implicit assumption: record size** -- The spec assumes records are small (the fixture data in `fixtures.ts` is ~14KB total for all collections). Added an escalation trigger for records exceeding 1MB.

5. **Contradiction check: "no auth" vs "userId field"** -- The spec says no auth in this slice but requires a `userId` field on records. Clarified: the field exists in the schema but is not enforced. A placeholder value (e.g., `"anonymous"`) is used until Slice 5 adds authentication.

6. **Missing: Dexie schema migration** -- Adding `_updatedAt`, `_createdAt`, `userId` to Dexie stores requires bumping the Dexie version number from 1 to 2. The current schema is `'&id, _updatedAt, _createdAt'` which already includes `_updatedAt` and `_createdAt` as indexed fields. Only `userId` needs adding. Added an escalation trigger for migration issues.

7. **Missing: what happens to the `config` collection?** -- `config` currently uses `localStorageCollectionOptions` (localStorage, not Dexie). It must migrate to the synced Dexie adapter. This is a breaking change for existing users who have config in localStorage. Mitigation: on first load, check localStorage for existing config data, migrate it to Dexie, then delete from localStorage.

8. **Ambiguity: "server is the clock authority"** -- Clarified that `_updatedAt` is set by the server on every write. The client sends its local timestamp for conflict detection (so the server can compare), but the server always overwrites it with its own clock on successful persist.

### Items needing user input:

- **Config collection migration:** The `config` collection currently uses `localStorage`. Moving it to Dexie+sync means existing users' config data must be migrated. Is a one-time migration acceptable, or should config remain local-only for now?

- **Soft delete vs hard delete:** Soft delete is better for offline sync (tombstones prevent re-insertion of deleted records on reconnect) but adds complexity. Confirm that soft delete with a `_deletedAt` timestamp is the desired approach.

- **Server database choice:** Spec prefers SQLite. Confirm this is acceptable for a 2-5 user deployment, or should we start with PostgreSQL for future scalability?
