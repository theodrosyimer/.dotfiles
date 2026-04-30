# False Positive Patterns — Common Noise and How to Exclude

These are recurring false positive patterns observed in AI code review systems.
When you encounter a false positive, check this list first — the exclusion may
already be documented here.

## By Reviewer Type

### Security Reviewer

```
COMMON FALSE POSITIVES — Security

1. "Missing rate limiting" on read-only public endpoints
   Exclusion: "Missing rate limiting on GET endpoints returning public data"

2. "Hardcoded string could be a secret" on non-sensitive constants
   Exclusion: "String constants that are clearly configuration values, not secrets
   (API base URLs, feature flag names, error message templates)"

3. "Missing CSRF protection" on API-only endpoints (no cookies)
   Exclusion: "CSRF concerns on stateless API endpoints using Bearer token auth"

4. "Input validation missing" when Zod schema exists at the boundary
   Exclusion: "Missing validation when Zod schema validation exists at the API
   boundary for this input"

5. "XSS risk" in server-side rendered content that's already escaped
   Exclusion: "XSS warnings when the templating engine auto-escapes by default"

6. Defense-in-depth suggestions on already-secured code
   Exclusion: "Defense-in-depth suggestions when primary defenses are adequate"
```

### Code Quality Reviewer

```
COMMON FALSE POSITIVES — Code Quality

1. "Function too long" without a concrete refactoring suggestion
   Exclusion: "'This function is too long' without a specific refactoring suggestion"

2. "Missing error handling" on operations that already have try/catch
   Exclusion: "Generic 'add error handling' on functions that already handle errors"

3. "Code duplication" on test fixtures/setup code
   Exclusion: "Code duplication in test fixtures — test isolation is more important"

4. "Unused import" that's actually a type import
   Exclusion: "Unused import warnings — the linter handles this"

5. "Missing return type" on private/internal functions
   Exclusion: "Missing return types on internal functions where TypeScript infers correctly"

6. Style preferences disguised as quality issues
   Exclusion: "Style preferences (single vs double quotes, trailing commas, semicolons)"
```

### Architecture Reviewer

```
COMMON FALSE POSITIVES — Architecture

1. "Should be in a separate module" for a small helper
   Exclusion: "'This should be a separate module' suggestions unless there's a clear
   bounded context violation"

2. "Barrel file detected" on package top-level index.ts
   Exclusion: "index.ts re-exports at monorepo package top-level (these are allowed)"

3. "Framework import in domain" for Zod (which is a boundary tool)
   Exclusion: "Zod imports in boundary schemas — Zod is allowed at boundaries per convention"

4. "Cross-module import" through the public gateway (which is correct)
   Exclusion: "Cross-module imports that go through the module's public contracts/ gateway"
```

### Performance Reviewer

```
COMMON FALSE POSITIVES — Performance

1. "Missing memoization" on cheap computations
   Exclusion: "Memoization suggestions on computations that are O(1) or O(n) with small n"

2. "N+1 query" in seed scripts or test setup
   Exclusion: "N+1 patterns in seed files, test fixtures, or migration scripts"

3. "Large bundle import" for tree-shakeable packages
   Exclusion: "Bundle size warnings for packages that are tree-shakeable by the bundler"

4. "Consider caching" on low-traffic endpoints
   Exclusion: "'Consider caching' on operations that aren't in hot paths"
```

### Testing Reviewer

```
COMMON FALSE POSITIVES — Testing

1. "vi.fn() used" for legitimate component callback props
   Exclusion: "vi.fn() is correct for React component callback props (onSubmit, onPress)"

2. "InMemory fake has too much logic" on production demo fakes (not test fakes)
   Exclusion: "InMemory fakes (Map-based) in non-test code — these are legitimate for
   demo/dev environments, not test doubles"

3. "Missing test coverage" when the change is in untestable infrastructure
   Exclusion: "Missing tests for pure infrastructure wiring (DI container config, module imports)"

4. "Shared test container detected" for shared fixtures (not shared state)
   Exclusion: "Shared fixture factory functions — these create new data, not shared state"
```

## Cross-Cutting False Positive Patterns

```
PATTERNS THAT AFFECT ALL REVIEWERS

1. Flagging issues in unchanged code
   → Already in shared rules, but if a reviewer ignores it, reinforce in its prompt

2. "Consider using library X" suggestions
   → Already in shared rules — these are opinion, not defects

3. Comments about code in deleted files
   → Reviewers should only look at added/modified lines

4. Flagging TODO comments
   → TODOs are tracked separately, not a review finding

5. Repeating the same finding for the same pattern across multiple files
   → The coordinator should deduplicate, but if it doesn't, add guidance
```

## When a False Positive Is Actually a True Positive

Before adding an exclusion, verify the user's reasoning. These are commonly
disputed but are actually real issues:

```
DISPUTED BUT REAL — Don't Exclude These

  ✅ "Missing ownership check" — even if auth middleware exists, ownership
     is a separate concern from authentication

  ✅ "Missing error state in UI" — "the backend won't fail" is not a valid
     reason to skip error handling in the frontend

  ✅ "Type assertion (as)" — if it can be avoided with a type guard, it should be

  ✅ "Missing NOT NULL constraint" — "the app always provides a value" breaks
     when another client writes to the same table
```

If the user insists on excluding a real issue, log it in the false positives
file with classification "disputed" rather than silently adding the exclusion.

[^1]: Ryan Skidmore — [Orchestrating AI Code Review at scale](https://blog.cloudflare.com/ai-code-review/)
