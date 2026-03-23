# Structure View: Tree Search Filter

## Intent

**Problem:** The Structure view displays the full nested file tree for both panels (left and right columns) with no way to locate a specific node. In the demo data alone there are ~35 nodes across 4 levels of nesting. For real-world projects with hundreds of files, users must visually scan and manually expand/collapse branches to find a file or directory by name.

**Desired outcome:** Users can type into a filter input at the top of each tree column and see the tree narrowed in real time to only nodes whose names match the query -- plus their ancestor nodes for context. Clearing the input restores the full tree.

**Rationale:** The primary purpose of the Structure view is to answer "where does code live?" A search filter is the most direct way to answer that question when the tree is large enough that visual scanning breaks down.

**Hypothesis:** We believe adding a live text filter to the Structure view's tree columns will result in users finding specific files and directories without manual tree scanning because the filter eliminates non-matching branches and auto-expands paths to matches.

## User-Facing Behavior

```
Scenario: Filtering narrows the tree to matching nodes
  Given the Structure view is loaded with tree data
  And the user focuses the filter input in a tree column
  When the user types "decide" into the filter input
  Then only nodes whose name contains "decide" (case-insensitive) are visible
  And every ancestor node of a matching node is also visible
  And ancestor nodes are displayed expanded (not collapsed)
  And the other tree column is unaffected

Scenario: Partial match works on any substring
  Given the Structure view is loaded with tree data
  When the user types "book" into the filter input
  Then nodes named "booking/", "request-booking/", "confirm-booking/",
       "cancel-booking/", "get-booking-detail/", "booking.module.ts",
       "booking.tokens.ts", "booking.controller.ts",
       "in-memory-booking-event-store.ts",
       "booking-event-store-failing-stub.ts",
       "drizzle-booking-event-store.ts",
       "booking-event-listener.nestjs.ts",
       "booking-gateway.ts", "booking-contract.shared.ts" are visible
  And their ancestor directories are also visible

Scenario: No matches displays an empty state message
  Given the Structure view is loaded with tree data
  When the user types "zzzznotfound" into the filter input
  Then no tree nodes are visible
  And a text message "No matching nodes" is displayed in the tree area

Scenario: Clearing the filter restores the full tree
  Given the user has typed "decide" into the filter input
  When the user clears the filter input (backspace or clear action)
  Then the full tree is displayed
  And collapse/expand state returns to its default (depth < 2 expanded)

Scenario: Filter is case-insensitive
  Given the Structure view is loaded with tree data
  When the user types "REQUEST" into the filter input
  Then nodes whose names contain "request" in any case are visible

Scenario: Each tree column has its own independent filter
  Given the Structure view shows two tree columns (left and right)
  When the user types "domain" into the left column's filter
  Then only the left column's tree is filtered
  And the right column's tree remains fully visible and unfiltered
```

## Feature Description

### Musts

- The filter input is placed between the column header (icon + label + tagline) and the scrollable tree area within the `TreeColumn` component.
- Filtering is performed entirely client-side against the in-memory `TreeNodeData[]` array -- no database queries, no collection changes.
- Matching is case-insensitive substring match on `TreeNodeData.name`.
- A node is visible if: (a) its `name` matches the query, OR (b) any descendant's `name` matches the query (ancestor preservation).
- When a filter is active, all visible ancestor nodes of matching nodes are rendered expanded regardless of their manual collapse/expand state.
- When the filter is cleared (empty string), the tree returns to normal behavior where `expanded` state is driven by user clicks and the default `depth < 2` rule.
- The filter function must be a pure utility: `(tree: TreeNodeData[], query: string) => TreeNodeData[]` that returns a pruned copy of the tree (no mutation of the original data).
- Leaf nodes that do not match and have no matching descendants are excluded from the filtered tree entirely (hidden, not greyed out).
- The filter input must be a standard `<input type="text">` element with `placeholder="Filter..."`.

### Must Nots

- Must not modify the `TreeNodeData` type or the `structure.schema.ts` schema.
- Must not filter across columns -- each column's filter is independent and self-contained.
- Must not persist filter state to the database, URL, or local storage. Filter state is ephemeral React component state.
- Must not add debouncing or throttling -- the tree sizes in this app are small enough that synchronous filtering on every keystroke is acceptable.
- Must not match against `desc`, `layer`, or any field other than `name`.
- Must not introduce any new npm dependencies.

### Preferences

- Place the tree-filtering pure function in a separate utility file (e.g., `src/views/structure/utils/filter-tree.ts`) to keep it independently testable.
- Use the existing Tailwind design tokens and styling conventions (monospace font, slate color palette, small text sizes) for the input element.
- Keep the input visually minimal -- a simple text input with a subtle border, consistent with the existing `border-slate-700/50 bg-slate-900/50` pattern used by the tree container.
- Manage the filter query string as `useState` within `TreeColumn`, keeping `StructureView` unchanged.

### Escalation Triggers

- If the tree filtering function takes more than 16ms for the demo dataset (measured via `performance.now()`), stop and reconsider the approach before proceeding.
- If implementing ancestor preservation requires modifying the `TreeNode` component's `expanded` prop in a way that breaks the existing click-to-toggle behavior when no filter is active, stop and ask.

## Acceptance Criteria

### Done Definition

- [ ] Each tree column in the Structure view displays a text input between its header row and the scrollable tree container.
- [ ] Typing into the input immediately filters the tree below it to show only nodes with matching names and their ancestors.
- [ ] Non-matching leaf nodes with no matching descendants are hidden from view.
- [ ] Ancestor nodes of matching nodes are always shown expanded while a filter is active.
- [ ] Clearing the input fully restores the original unfiltered tree with default expand/collapse behavior.
- [ ] The two columns filter independently -- filtering one does not affect the other.
- [ ] When no nodes match, the text "No matching nodes" is displayed in the tree area.
- [ ] No changes to `structure.schema.ts` or the `TreeNodeData` type.
- [ ] The tree filter utility is a pure function with no side effects.

### Test Cases

| Input | Expected Output | Notes |
|-------|----------------|-------|
| Query: `"decide"` against demo left tree | Returns subtree: `booking/ > domain/ > decide.ts` | Single leaf match; two ancestors preserved |
| Query: `"domain"` against demo left tree | Returns: `booking/ > domain/`, `space-listing/ > domain/` (with all their children) | Directory name match includes all children |
| Query: `"BOOKING"` against demo left tree | Same results as `"booking"` | Case-insensitive |
| Query: `""` (empty string) | Returns the full original tree unchanged | Identity case |
| Query: `"zzzznotfound"` against demo left tree | Returns `[]` (empty array) | Zero-match case |
| Query: `"drizzle"` against demo right tree | Returns: `modules/booking/ > repositories/ > drizzle-booking-event-store.ts` | Right column filtered independently |
| Query: `"ts"` against demo left tree | Returns all nodes whose name contains "ts": `types/`, `dtos/booking-transfer-types.ts`, `booking.tokens.ts`, `decide.ts`, `evolve.ts`, `result.ts`, `types.ts`, `test-dsl.ts`, etc. plus their ancestors | Substring match, not extension match |
| Query: `"request-booking"` against demo left tree | Returns: `booking/ > slices/ > request-booking/` with all its children visible | Directory match includes children |

---

## Task Decomposition

### Task 1: Tree filter utility function (small)

**Input:** `TreeNodeData[]` and a `query` string.
**Output:** A new `TreeNodeData[]` containing only matching nodes and their ancestors, with the subtree structure preserved.

**File:** `src/views/structure/utils/filter-tree.ts`

**Logic:**
- If `query` is empty, return the original array.
- Recursively walk the tree. For each node:
  - Recursively filter its children first.
  - A node is included if its `name` contains the query (case-insensitive) OR if it has any surviving children after filtering.
  - If the node's name matches, include all its original children (not just filtered ones) -- matching a directory shows its full contents.
  - Return a new node object with the (possibly filtered) children array.

**Acceptance criterion it satisfies:** "The tree filter utility is a pure function" + all test case rows.

### Task 2: Integrate filter input into TreeColumn (small)

**Input:** The filter utility from Task 1.
**Output:** Updated `TreeColumn` component with a text input and filtered tree rendering.

**Files modified:** `src/views/structure/components/tree-column.tsx`

**Changes:**
- Add `useState<string>('')` for the filter query.
- Add an `<input>` element between the header div and the scrollable tree div.
- Call the filter utility with the tree prop and query state.
- Pass the filtered tree to `TreeNode` rendering.
- When query is non-empty and filtered result is empty, render the "No matching nodes" message instead of tree nodes.

**Acceptance criterion it satisfies:** "Each tree column displays a text input" + "Typing filters the tree" + "No matching nodes" message + column independence.

### Task 3: Force-expand ancestors during active filter (small)

**Input:** The active filter query string.
**Output:** `TreeNode` components expand automatically when a filter is active.

**Files modified:** `src/views/structure/components/tree-column.tsx` and `src/views/structure/components/tree-node.tsx`

**Changes:**
- Pass a `filterActive: boolean` prop from `TreeColumn` to `TreeNode`.
- In `TreeNode`, when `filterActive` is true, treat all nodes with children as expanded (override the local `expanded` state for display purposes without mutating it).
- When `filterActive` becomes false, the original `expanded` state resumes control.

**Acceptance criterion it satisfies:** "Ancestor nodes of matching nodes are always shown expanded while a filter is active" + "Clearing the input fully restores the original unfiltered tree with default expand/collapse behavior."

---

## Stress-Test Review

**Issues found and fixed inline:**

1. **Ambiguity: what happens when a directory name matches?** The original user request said "search tree node names" without specifying whether matching a directory shows its children. I resolved this in Task 1's logic: matching a directory name includes all its original children. This matches the user's mental model -- finding `booking/` means you want to see what is inside it.

2. **Ambiguity: expand state after clearing filter.** The original behavior uses `useState(depth < 2)` as the initial expand state. I specified that clearing the filter returns to "default" behavior, meaning the existing `expanded` state (which may have been toggled by the user before filtering) is restored, not reset. The Task 3 approach of overriding display without mutating state handles this correctly.

3. **Edge case: root nodes with no layer.** The demo data has root nodes like `booking/` with `layer: null`. These are just structural containers. The filter correctly handles them as ancestors since the filter operates on `name` only, not `layer`.

4. **Missing specification: keyboard shortcut.** The user did not request a keyboard shortcut (e.g., Cmd+F) to focus the filter. This is intentionally not included to keep scope minimal. If desired, it would be a separate slice.

5. **Potential contradiction check:** The "Clearing the filter restores the full tree" scenario says "collapse/expand state returns to its default (depth < 2 expanded)." This could contradict the Task 3 approach of preserving user-toggled expand state. **Resolution:** The BDD scenario wording is imprecise -- the actual behavior is that manual expand/collapse state is preserved (the user's clicks are not lost). The scenario means "the expand behavior is no longer overridden by the filter," which the Task 3 approach achieves. The scenario wording has been left as-is because the acceptance criteria (Done Definition) are more precise and authoritative.

**Items that could use user input (non-blocking):**

- **Match highlighting:** Should the matching substring within a node's name be visually highlighted (e.g., bold or colored)? This is not specified and is left out of scope. It would be a clean follow-up slice.
- **Filter input clear button:** Should there be an "X" button inside the input to clear the filter with one click? Not specified; the user can select-all and delete or backspace. A clear button would be a minor enhancement.
