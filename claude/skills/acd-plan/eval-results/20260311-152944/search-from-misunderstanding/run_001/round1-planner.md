# Phase 1: Initial Framing

## Investigation Findings

I searched the entire `archviz` codebase for any search functionality and found **none**. Specifically:

- **No search-related source files** exist under `src/`. A glob for `*search*` returned only `node_modules` hits (library internals, Lucide icons).
- **No `<input>` elements** exist anywhere in the source code. There are zero text inputs, search bars, or filter controls in any view.
- **No filtering or query logic** beyond `useLiveQuery()` calls that fetch entire collections for display and `.find()` calls for internal array lookups (e.g., selecting the active scenario by ID).
- The app has **three read-only visualization views** (Structure, Data Flow, Error Boundary) that render data from TanStack DB collections. Users can load demo data via a kebab menu, but there is no mechanism to search or filter that data.
- The README confirms the app is in **Phase 1 (read-only collections)**, with inline editing planned for Phase 2. Search is not mentioned in the roadmap at all.

## Honest Assessment

**Search functionality does not exist in this codebase.** There is no search feature that is "broken" because there is no search feature at all. The user's report -- "users type a query and get no results even though matching items exist in the database" -- cannot describe a bug in the current application because there is no UI where users can type a query.

This means one of the following is true:

1. **The user is describing a feature that needs to be built**, not a bug to be fixed. They may be experiencing the absence of search as a broken experience.
2. **The user is referring to a different application or a planned feature** that has not been implemented yet.
3. **The user is conflating browser-level search (Ctrl+F)** with an in-app search feature.

## Reframed Hypothesis (Conditional)

I cannot state a testable hypothesis for a bug fix because the reported bug has no corresponding code. If the intent is to build search, the hypothesis would be:

> "We believe **adding a search/filter input to the visualization views** will result in **users being able to find specific items (nodes, steps, scenarios) within loaded data** because **the current views display all data without any way to locate specific items in large datasets**."

However, I need the user to confirm this reframing before proceeding.

---

# Phase 2: Deep-Dive Interview

## Clarifying Questions

Given that search does not exist in the codebase, I need to resolve the fundamental mismatch between the bug report and reality before asking implementation-level questions.

### 1. Are you describing a missing feature or a bug in existing code?

The archviz application has no search UI -- no text inputs, no filter controls, no query mechanism. The three views (Structure, Data Flow, Error Boundary) render their full datasets without any search or filtering. Can you clarify whether you are reporting a bug in code that exists somewhere I have not found, or whether you are requesting that a search feature be built?

### 2. If this is a feature request: which view(s) need search?

The app has three distinct views, each with different data shapes:
- **Structure** -- tree panels with nodes (files/folders organized by architectural layer)
- **Data Flow** -- ordered steps in a command pipeline with state transitions
- **Error Boundary** -- scenarios with swim-lane steps across infrastructure layers

Should search apply to one specific view, or should it be a global search across all three?

### 3. What does "matching items" mean concretely?

You mentioned "matching items exist in the database." What kind of items are users trying to find? Node names in the structure tree? Step descriptions in data flow? Scenario names in error boundary? Understanding the target data shapes will determine whether this is a simple text filter or something more structured.

### 4. Where did the expectation of search come from?

Is there a design mock, a user story, or a prior conversation that established search as a feature of this app? This will help me understand the expected scope and behavior.

### 5. Is there a different codebase or branch where search was implemented?

Is it possible that search was built on a feature branch, in a fork, or in a different project that shares the "archviz" name? The `main` branch at `HEAD` (commit `27e0ba1`) has no search code whatsoever.
