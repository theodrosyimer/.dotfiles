# Trigger Patterns — File-Match Patterns for Conditional Reviewers

Tier 2 and Tier 3 reviewers activate based on which files changed in the diff.
Triggers are functions that receive a `DiffEntry` and return `boolean`.

## CI Trigger Format (TypeScript)

```typescript
// DiffEntry shape
type DiffEntry = {
  path: string;       // "src/modules/booking/slices/create/handler.ts"
  status: string;     // "added" | "modified" | "deleted" | "renamed"
  addedLines: number;
  removedLines: number;
  patch: string;      // full diff patch content
};

// Trigger function
triggers: (entry: DiffEntry) => boolean
```

## Common Patterns

### By File Extension

```typescript
// TypeScript/JavaScript source files
(e) => /\.(ts|tsx)$/.test(e.path)

// SQL files
(e) => /\.sql$/.test(e.path)

// Markdown/docs
(e) => /\.md$/.test(e.path)

// Config files
(e) => /\.(json|yaml|yml|toml)$/.test(e.path)
```

### By Path Segment

```typescript
// Any file in a specific directory
(e) => /migration/.test(e.path)
(e) => /infrastructure\//.test(e.path)

// Multiple path patterns (OR)
(e) => /(component|hook|screen|page)/.test(e.path)

// Specific module
(e) => /modules\/booking\//.test(e.path)
```

### Combined Patterns

```typescript
// TypeScript files in specific directories
(e) => /\.(ts|tsx)$/.test(e.path) &&
  /(repository|query|handler|hook|api|route|controller)/.test(e.path)

// Test files only
(e) => /\.(test|spec)\.(ts|tsx)$/.test(e.path)

// Package config files
(e) => /(package\.json|pnpm-lock\.yaml|\.npmrc)/.test(e.path)
```

### By Status

```typescript
// Only new files (not modifications)
(e) => e.status === "added"

// Only deletions (for cleanup reviewers)
(e) => e.status === "deleted"
```

## Existing Reviewer Triggers (Reference)

```
REVIEWER          TRIGGER PATTERN                              RATIONALE
──────────────────────────────────────────────────────────────────────────────
performance       .ts/.tsx + repository|query|handler|hook      Only code that touches data/API
testing           .test.ts|.spec.ts + fake|fixture|stub         Only test-related files
documentation     README|CHANGELOG|.md|controller|gateway       Docs + API surface
frontend          .tsx + component|hook|screen|page|layout      UI layer only
database          migration|schema|drizzle|.sql|seed            DB-related files
dependency        package.json|pnpm-lock.yaml|.npmrc            Package management
release           CHANGELOG|version|release|workflows|ci        Release pipeline
```

## Subagent Trigger (Description)

For Claude Code subagents, triggers are expressed in the `description` field
as natural language. The main agent uses this to decide when to delegate:

```yaml
description: >-
  Reviews code changes for performance issues. Use when reviewing diffs
  that touch database queries, API handlers, React hooks, or data fetching code.
```

The description should mirror the CI trigger patterns in natural language.

## Anti-Patterns

```
TRIGGER ANTI-PATTERNS

  ❌ null triggers on Tier 2/3 (runs on everything — defeats the purpose)
  ❌ Triggers too narrow (misses relevant files)
  ❌ Triggers on lock files (already filtered by noise filter)
  ❌ Triggers on .min.js/.map (already filtered by noise filter)
```
