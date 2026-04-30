---
name: reviewer-authoring
description: >-
  Create new specialised AI code reviewer agents for the ai-reviewer system.
  Generates both the Claude Code subagent (.claude/agents/) and the CI reviewer
  file (src/reviewers/) from the same input to keep them in sync. Use this skill
  when the user says "add reviewer", "new reviewer", "create reviewer for",
  "I need a reviewer that checks", "add review agent", or describes a new domain
  that should be covered by the code review system. Also trigger when the user
  wants to split an existing reviewer into more specialised sub-reviewers.
---

# Reviewer Authoring

Create new specialised AI code reviewer agents that work in both Claude Code
(as subagents) and CI (as TypeScript reviewer definitions). Every new reviewer
is generated in both locations from the same input.

## Skill Contents

```
reviewer-authoring/
├── SKILL.md                                          ← You are here
└── references/
    ├── reviewer-template.md                          ← Blank template with required sections
    ├── trigger-patterns.md                           ← File-match trigger patterns reference
    └── ai-code-review-orchestration-at-scale.md      ← Full Cloudflare system reference
```

**Before creating a reviewer, read `references/reviewer-template.md`.**
For trigger pattern guidance, read `references/trigger-patterns.md`.
For system design principles, read `references/ai-code-review-orchestration-at-scale.md`.

---

## Workflow: Create a New Reviewer

### Step 1 — Define the Domain

Ask the user (if not already provided):

1. **What domain** does this reviewer cover? (e.g., "accessibility", "i18n", "API design")
2. **What tier** should it be?
   - **Tier 1 (always)**: Runs on every review. Only for fundamental concerns (security, quality, architecture).
   - **Tier 2 (conditional)**: Runs when changed files match trigger patterns. Most new reviewers go here.
   - **Tier 3 (optional)**: Only runs when explicitly enabled. For niche concerns.
3. **What file patterns** trigger it? (for Tier 2/3)

### Step 2 — Draft the Prompt

Read `references/reviewer-template.md` for the required structure.

Draft the prompt with the user, ensuring:

1. **Role declaration**: 1-2 sentences establishing the domain and tech stack context
2. **"What to Flag"**: 5-10 specific, actionable items ordered by severity
3. **"What NOT to Flag"**: 5-10 specific exclusions — start with the common patterns from `references/false-positive-patterns.md` (in the `reviewer-prompt-tuning` skill) that apply to this domain
4. Every "What to Flag" item must be **concrete enough that a human reviewer could verify the finding**

Present the draft to the user for review before generating files.

### Step 3 — Generate the Subagent File

Create `.claude/agents/{domain}-reviewer.md`:

```markdown
---
name: {domain}-reviewer
description: >-
  Reviews code changes for {domain} issues. Use when reviewing diffs
  that touch {relevant file types/patterns}.
tools: Read, Grep, Glob
model: sonnet
---

{The full reviewer prompt from Step 2}

## Output Format

Report your findings as a structured list. For each finding:

1. **Severity**: critical / warning / suggestion
2. **File**: path/to/file.ts
3. **Line**: line number (if applicable)
4. **Finding**: clear description of the issue
5. **Suggestion**: concrete fix or recommendation

If you find no issues, say "No {domain} issues found."
```

### Step 4 — Generate the CI Reviewer File

Create `src/reviewers/{domain}.ts`:

```typescript
import type { ReviewerDefinition } from "../lib/types.ts";

export const {domain}Reviewer = {
  name: "{domain}",
  tier: "{tier}",
  triggers: {trigger function or null},
  systemPrompt: `{The same prompt from Step 2}`,
} satisfies ReviewerDefinition;
```

### Step 5 — Register in the CI

Add the import and entry to `src/reviewers/registry.ts`:

1. Add import: `import { {domain}Reviewer } from "./{domain}.ts";`
2. Add to `ALL_REVIEWERS` array under the correct tier comment

### Step 6 — Verify Sync

Confirm that:
- The subagent `.md` and CI `.ts` have **identical** "What to Flag" and "What NOT to Flag" sections
- The trigger patterns match between `triggers` in the `.ts` and the `description` in the `.md`
- The tier assignment is correct for the domain

---

## Workflow: Split an Existing Reviewer

When a reviewer covers too broad a domain (signal ratio dropping, too many
false positives in one area):

1. Identify which findings should move to a new reviewer
2. Create the new reviewer using the workflow above
3. Remove the moved items from the original reviewer's "What to Flag"
4. Add exclusions to the original: "Don't flag {moved domain} — handled by {new reviewer}"
5. Update both subagent and CI files for the original reviewer

---

## Quality Checklist

Before delivering a new reviewer:

- [ ] "What to Flag" has 5-10 specific, actionable items
- [ ] "What NOT to Flag" has 5-10 specific exclusions (not empty!)
- [ ] Subagent file created in `.claude/agents/`
- [ ] CI file created in `src/reviewers/`
- [ ] CI file registered in `src/reviewers/registry.ts`
- [ ] Prompt text is identical in both locations
- [ ] Trigger patterns are appropriate for the domain
- [ ] Tier assignment matches the domain's importance
- [ ] Model is `sonnet` for subagent (override to `haiku` only for text-heavy lightweight tasks)
- [ ] Subagent tools are `Read, Grep, Glob` (read-only — reviewers don't modify code)
