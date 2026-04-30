---
description: >-
  Run a full AI code review on the current branch's diff against the target branch.
  Spawns specialised reviewer subagents in parallel, collects findings, deduplicates,
  and produces a consolidated review. Uses the same reviewer prompts as the CI pipeline.
argument-hint: "<target-branch or blank for main>"
---

# Local AI Code Review

Run the same multi-agent review pipeline locally that CI runs on merge requests.

## Procedure

### Step 1 — Determine Target Branch

If `$ARGUMENTS` is provided, use it as the target branch.
If blank, default to `main`.

### Step 2 — Extract Diff and Shared Context

Run these commands to gather the review context:

```bash
# Get changed files list
git diff --name-only origin/{target}...HEAD

# Get full diff
git diff origin/{target}...HEAD
```

Write the shared context to a temp file `.claude/review-context.tmp.md`:

```markdown
# Review Context (shared — do not duplicate in subagent prompts)

## Changed Files

{list of changed files with +/- line counts}

## Full Diff

{full diff output}
```

This file is read by each reviewer subagent, avoiding context duplication
across all parallel sessions (Cloudflare's shared context optimization).

### Step 3 — Filter Noise

Exclude from review:

- Lock files: `bun.lock`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`
- Minified/bundled: `.min.js`, `.min.css`, `.bundle.js`, `.map`
- Generated files with `// @generated` or `/* eslint-disable */` markers
- **Exception**: Database migrations — always review even if marked generated

### Step 4 — Classify Risk Tier

Based on the filtered diff:

```
TRIVIAL (≤10 lines, ≤5 files, no security paths):
  → Spawn: @security-reviewer, @code-quality-reviewer, @architecture-reviewer

LITE (≤100 lines, ≤20 files):
  → Spawn: Tier 1 + matching Tier 2 reviewers

FULL (>100 lines, >50 files, or security-sensitive paths):
  → Spawn: All matching reviewers
```

Security-sensitive paths: anything matching `auth/`, `crypto/`, `security/`,
`guard/`, `token/`, `session/`, `iam/`, `permission/`.

### Step 5 — Spawn Reviewer Subagents

For each active reviewer, delegate with `@{reviewer-name}-reviewer`:

```
@security-reviewer Read .claude/review-context.tmp.md and review the changed files for security issues.
@code-quality-reviewer Read .claude/review-context.tmp.md and review the changed files for code quality issues.
@architecture-reviewer Read .claude/review-context.tmp.md and review the changed files for architecture violations.
```

Spawn Tier 2 reviewers only if changed files match their trigger patterns:

- `@performance-reviewer`: if `.ts/.tsx` files touch repository/query/handler/hook/controller
- `@testing-reviewer`: if `.test.ts/.spec.ts` or fake/fixture/stub files changed
- `@documentation-reviewer`: if README/CHANGELOG/.md/controller/gateway files changed
- `@frontend-reviewer`: if `.tsx` or component/hook/screen/page files changed
- `@database-reviewer`: if migration/schema/drizzle/.sql files changed

### Step 6 — Consolidate Findings

After all subagents return:

1. **Collect** all findings from each reviewer
2. **Deduplicate**: same issue flagged by multiple reviewers → keep once in the best-fit category
3. **Re-categorise**: findings in the wrong reviewer's domain → move to correct category
4. **Filter**: drop speculative, vague, or already-handled findings
5. **Classify** overall decision:
   - `approved`: no findings or trivial suggestions only
   - `approved_with_comments`: suggestions + few warnings, no risk pattern
   - `minor_issues`: multiple warnings suggesting risk pattern
   - `significant_concerns`: any critical finding

### Step 7 — Report

Present the consolidated review inline with:

- Decision (approved / approved_with_comments / minor_issues / significant_concerns)
- Summary (2-3 sentences)
- Findings grouped by reviewer, each with severity emoji (🔴/🟡/🔵), file, line, description, and suggestion

### Step 8 — Cleanup

Delete `.claude/review-context.tmp.md` after the review completes.
