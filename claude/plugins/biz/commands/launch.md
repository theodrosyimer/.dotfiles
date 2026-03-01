---
description: Start, resume, or check progress on a SaaS project launch workflow. Orchestrates all skills in sequence with persistent progress tracking.
argument-hint: "[project-codename] or leave blank to list projects"
---

# /launch — SaaS Project Launch Workflow

## What This Command Does

Orchestrates the full SaaS launch workflow across multiple sessions. Tracks progress in a persistent file so you can pause, resume, skip steps, and pick up exactly where you left off — even days or weeks later.

## Usage

```
/launch                     → List all projects and their status
/launch project1           → Resume or start project "project1"
/launch project1 status    → Show detailed progress for "project1"
/launch project1 skip 4    → Skip step 4 (email-marketing) for now
/launch project1 unskip 4  → Re-enable a skipped step
/launch project1 notes 2 "Need to research competitor pricing first"  → Add notes to step 2
```

## Workflow Steps

| # | Step | Skill Invoked | Outputs |
|---|------|---------------|---------|
| 1 | Validate idea | `viability-analysis` | viability/ folder with phase reports + scorecard |
| 2 | Plan the product | `saas-intake` | intake-questionnaire.md |
| 3 | Name & position | `product-naming` | naming-decisions.md |
| 4 | Email sequences | `email-marketing` | email-sequences.md |
| 5 | Legal & infra setup | `legal-guide` + `github-strategy` | legal-notes.md, github-setup.md |
| 6 | Build & ship | *Manual — no skill* | User builds the product |
| 7 | Scale-up planning | `saas-scaleup` | scaleup-questionnaire.md |

## Command Logic

### When `/launch` is called with no arguments:

1. Scan for `projects/*/progress.md` files
2. If none found → "No projects yet. Run `/launch <codename>` to start one."
3. If found → show a summary table:

```
Your Projects:
| Project     | Current Step           | Progress | Last Updated |
|-------------|------------------------|----------|--------------|
| project1   | 2. Plan the product    | 2/7      | 2026-03-01   |
| project2 | 1. Validate idea       | 0/7      | 2026-02-28   |
```

### When `/launch <codename>` is called:

1. Check if `projects/<codename>/progress.md` exists
2. **If new project:**
   a. Create `projects/<codename>/` directory
   b. Generate `progress.md` from the template below
   c. Ask: "Ready to start with idea validation? Tell me about your idea."
   d. Invoke the `viability-analysis` skill
3. **If existing project:**
   a. Read `progress.md`
   b. Find the current step (first non-done, non-skipped step)
   c. Show status summary
   d. Ask: "Ready to continue with [current step]?" or suggest next action
   e. Invoke the appropriate skill

### When a skill completes:

1. Update `progress.md`:
   - Set current step status to `✅ done`
   - Set completion date
   - Add any relevant notes (e.g., viability score, key decisions)
2. Show updated progress
3. Check if next step has prerequisites met
4. Ask: "Ready to move to [next step]? Or would you like to pause here?"

### Special handling per step:

**Step 1 (viability-analysis):**
- After completion, check the scorecard decision:
  - 🟢 Strong Go → "Great score! Moving to detailed planning."
  - 🟡 Conditional Go → "Some weak areas. Want to address them before planning, or proceed?"
  - 🟠 Pivot → "The scorecard suggests rethinking. Want to revisit specific phases?"
  - 🔴 Kill → "The data suggests this idea isn't viable. Want to archive and start a new project?"
- If Kill → mark project as `archived` in progress.md, don't proceed

**Step 2 (saas-intake):**
- Pre-fill from viability analysis findings and profiles
- Note which sections are complete vs need more input

**Step 3 (product-naming):**
- Feed intake questionnaire context (target market, brand preferences, competitors)
- Save final name decision to progress notes

**Step 5 (legal + github):**
- This is two skills in one step — run them sequentially or let user choose order
- Legal may not apply if user isn't in France → offer to skip

**Step 6 (build & ship):**
- No skill to invoke — this is the user's manual work
- Show: "This step is on you! When you've launched (or have an MVP ready), run `/launch <codename>` again and I'll mark it done."
- Ask user to confirm when ready to move to step 7

**Step 7 (saas-scaleup):**
- Only relevant after real users and revenue
- If user arrives here early: "This step works best with real metrics. Do you have MRR and customer data?"

## Progress File Template

When creating a new project, generate this file at `projects/<codename>/progress.md`:

```markdown
# Project: <CODENAME>

> Created: <DATE>
> Last updated: <DATE>
> Status: 🚀 Active

---

## Launch Progress

| # | Step | Skill | Status | Started | Completed | Notes |
|---|------|-------|--------|---------|-----------|-------|
| 1 | Validate idea | viability-analysis | ⏳ pending | — | — | |
| 2 | Plan the product | saas-intake | ⏳ pending | — | — | |
| 3 | Name & position | product-naming | ⏳ pending | — | — | |
| 4 | Email sequences | email-marketing | ⏳ pending | — | — | |
| 5 | Legal & infra | legal-guide + github-strategy | ⏳ pending | — | — | |
| 6 | Build & ship | — | ⏳ pending | — | — | |
| 7 | Scale-up | saas-scaleup | ⏳ pending | — | — | |

## Current Step: 1 — Validate idea
## Blockers: None
## Key Decisions: (updated as project progresses)

---

## Decision Log

Decisions are logged here as the project progresses. Each entry includes the date, what was decided, and why.

<!-- Entries added automatically as skills complete -->
```

## Status Icons

| Icon | Meaning |
|------|---------|
| ⏳ pending | Not started yet |
| 🔄 in progress | Currently working on this |
| ✅ done | Completed |
| ⏭️ skipped | Deliberately skipped (can unskip later) |
| 🚫 blocked | Waiting on something |
| 📦 archived | Project killed or shelved |

## Progress Update Rules

When updating `progress.md`, always:
1. Update the `Last updated` date
2. Update the specific step's Status, Started, Completed, and Notes columns
3. Update the `Current Step` line to reflect the next actionable step
4. Add to the Decision Log if a significant decision was made
5. Update Blockers if any exist

## Multi-Session Continuity

This workflow is designed to span days, weeks, or months. Key behaviors:

- **Always read `progress.md` first** before doing anything on a project
- **Never re-do completed steps** unless the user explicitly asks to redo them
- **Carry context forward**: when starting step 3, read the outputs from steps 1 and 2
- **Respect skips**: skipped steps might be revisited later — don't nag about them
- **Handle pauses gracefully**: if the user says "pause" or "I'll come back later", update progress and confirm where they'll resume

## Edge Cases

- **User wants to redo a step**: "Want to redo step 2? I'll keep the old version as a backup and generate a fresh one."
- **User wants to work on steps out of order**: Allow it, but warn if prerequisites are missing ("Step 3 works better with a completed intake questionnaire from step 2.")
- **User has multiple projects**: Each project has its own `projects/<codename>/` folder — they're fully independent
- **User renames their project**: Update the codename in `progress.md` and the folder name
