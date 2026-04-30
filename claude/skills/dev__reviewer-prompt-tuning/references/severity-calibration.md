# Severity Calibration — When to Use Each Level

Consistent severity classification is what makes the approval rubric work.
If reviewers inflate severity, engineers learn to ignore findings. If they
deflate, real issues slip through.

## Severity Definitions

```
SEVERITY LEVELS

CRITICAL — Must fix before merge
  Will cause an outage, data loss, security breach, or data corruption
  in production. Not theoretical — the failure path is concrete and reachable.

  Examples:
    SQL injection in user-facing endpoint
    Auth bypass allowing unauthenticated access to protected resource
    Destructive DB migration without data preservation on populated table
    Unhandled promise rejection in request handler (crashes server)
    PII written to application logs in production

  NOT critical:
    Missing rate limiting (warning unless on auth/payment endpoints)
    Potential XSS in admin-only internal tool (warning)
    Missing input validation on non-security-sensitive fields (warning)


WARNING — Should fix, doesn't block alone
  Measurable regression, concrete risk, or violation of architectural
  invariants. A single warning in a clean MR gets approved_with_comments.
  Multiple warnings suggesting a risk pattern → minor_issues.

  Examples:
    N+1 query on endpoint handling >100 requests/minute
    Module boundary violation (importing domain from another module)
    Missing error state in UI component that fetches data
    Test without meaningful assertions
    Missing NOT NULL constraint where domain requires a value

  NOT warning:
    Potential N+1 in a seed script (suggestion)
    Missing JSDoc on internal function (suggestion)
    Naming inconsistency that doesn't affect readability (suggestion)


SUGGESTION — Worth considering, no functional impact
  Improvement in readability, maintainability, or consistency. The author
  may reasonably disagree. Never blocks a merge.

  Examples:
    Naming could be clearer (but current name isn't misleading)
    Code duplication that could be extracted (but isn't causing bugs)
    Missing memoization on non-hot-path computation
    Missing JSDoc on exported function
    Minor type safety improvement (narrowing a union)

  NOT suggestion:
    Formatting preferences (not even suggestion — skip entirely)
    Import ordering (skip)
    "Consider using library X" (skip unless there's a security issue)
```

## Context-Dependent Severity

The same issue type can have different severities depending on context.
When adding severity guidance to a reviewer prompt, use this pattern:

```
SEVERITY DEPENDS ON CONTEXT

Missing rate limiting:
  → auth/login endpoints: critical (brute force risk)
  → payment endpoints: critical (abuse risk)
  → public GET endpoints: suggestion (nice-to-have)
  → internal admin endpoints: warning

Missing input validation:
  → trust boundary (API input from external): warning
  → internal function parameter: suggestion (type system handles this)
  → database query parameter: critical (injection risk)

N+1 query pattern:
  → hot path (>100 req/min): warning
  → admin dashboard (low traffic): suggestion
  → seed/migration script: skip entirely
  → test setup code: skip entirely
```

## Approval Rubric (Coordinator)

The coordinator uses severity to make approval decisions. Reviewers must
classify correctly for this to work:

```
APPROVAL DECISION MATRIX

CONDITION                                    DECISION
──────────────────────────────────────────────────────────────
All LGTM or trivial suggestions only         approved
Only suggestions                             approved_with_comments
Few warnings, no risk pattern                approved_with_comments
Multiple warnings suggesting risk pattern    minor_issues
Any critical finding                         significant_concerns (blocks merge)

BIAS: Explicitly toward approval. A single warning in a clean MR
gets approved_with_comments, NOT blocked.
```

[^1]: Ryan Skidmore — [Orchestrating AI Code Review at scale](https://blog.cloudflare.com/ai-code-review/)
