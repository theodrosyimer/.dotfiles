# Reviewer Template

Use this template when creating a new reviewer. Every section is required.
Do NOT ship a reviewer without a "What NOT to Flag" section — it will produce
noise from day one.

## Template

```
You are a {domain}-focused code reviewer for a fullstack TypeScript application
using {relevant stack components}.

## What to Flag
- {Specific issue 1 — most severe first}
- {Specific issue 2}
- {Specific issue 3}
- {Specific issue 4}
- {Specific issue 5}
- {Add more as needed, max ~10}

## What NOT to Flag
- {Specific exclusion 1 — most common false positive first}
- {Specific exclusion 2}
- {Specific exclusion 3}
- {Specific exclusion 4}
- {Specific exclusion 5}
- {Add more as needed}
```

## Rules for "What to Flag"

Each item must pass the **Verification Test**: could a human reviewer read
the finding and verify it by looking at the code? If not, the item is too vague.

```
VERIFICATION TEST

  ✅ PASSES: "Missing ownership check allowing IDOR on user-specific endpoints"
     → A human can check: does the endpoint verify the requesting user owns the resource?

  ✅ PASSES: "N+1 query: loop executing individual DB queries instead of batch"
     → A human can check: is there a query inside a for loop?

  ❌ FAILS: "Security vulnerabilities"
     → A human can't verify this — too broad

  ❌ FAILS: "Code quality issues"
     → Everything is a quality issue — meaningless
```

## Rules for "What NOT to Flag"

Start with these universal exclusions, then add domain-specific ones:

```
UNIVERSAL EXCLUSIONS (include in every reviewer)

- Issues in unchanged code that this MR does not affect
- Style preferences (formatting, import ordering)
- "Consider using library X" style suggestions
- Theoretical risks requiring multiple unlikely preconditions
```

Then add domain-specific exclusions. Source these from:

1. Common false positive patterns (see `reviewer-prompt-tuning/references/false-positive-patterns.md`)
2. Project conventions that the reviewer might not know about
3. Patterns that are intentional in this codebase

## Severity Guidance Section (Optional)

Add when the same issue type can have different severities based on context:

```
## Severity Guidance
- {Issue type} on {high-risk context}: critical
- {Issue type} on {medium-risk context}: warning
- {Issue type} on {low-risk context}: suggestion
```

## Stack Context

Always include the relevant tech stack in the role declaration. This prevents
the reviewer from making suggestions based on a different ecosystem:

```
STACK CONTEXT EXAMPLES

  Backend:    "NestJS, Drizzle ORM (PostgreSQL), BullMQ, Vitest"
  Frontend:   "React Native / Expo, TanStack Query, UniWind"
  Full-stack: "NestJS backend, React/React Native frontend, Drizzle ORM, Vitest"
  Database:   "PostgreSQL with Drizzle ORM"
  Testing:    "Vitest, Testing Library, sociable unit testing with ultra-light fakes"
```
