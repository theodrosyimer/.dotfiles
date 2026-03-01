---
name: viability-analysis
description: "Run a structured pre-build viability analysis for any new SaaS or app idea. Trigger whenever the user mentions validating an idea, checking viability, 'should I build this', 'new SaaS idea', 'new app idea', 'viability analysis', 'validate this project', 'is this worth building', or any variation of evaluating whether a product idea is worth pursuing. Also trigger when the user says 'run step 0', references the Pre-Build Viability Analysis Framework, or asks to compare multiple ideas. This skill runs 6 research phases with web search, produces structured reports, spreadsheets, visual artifacts, and a weighted scorecard with a Go/No-Go decision. Use this skill even if the user just casually mentions a new idea — proactively suggest validation before they commit to building."
---

# Viability Analysis Skill

Validate SaaS/app ideas before writing code. Runs 6 research phases, produces structured outputs, and delivers a weighted Go/No-Go scorecard.

## Skill Contents

```
viability-analysis/
├── SKILL.md                              ← You are here
├── references/
│   └── framework.md                      ← Full 6-phase framework (prompts, scoring, methodology)
├── assets/
│   ├── phase-report-template.md          ← Shared markdown report template
│   ├── persona-card.html                 ← Phase 2 visual persona card (editable)
│   └── scorecard.html                    ← Interactive radar chart + decision display
└── scripts/
    └── build_spreadsheets.py             ← Generates scorecard.xlsx + competitive-data.xlsx
```

**Before starting any analysis, read `references/framework.md`** — it contains the prompt templates, scoring guide, and methodology for all 6 phases.

---

## Inputs

The user provides:
1. **An idea description** — what they want to build and for whom (can be vague)
2. **Execution mode** — guided (interactive) or full-run (autonomous). If not specified, ask.

If the idea description is too vague to start Phase 1 (less than a problem + target user), ask clarifying questions before proceeding.

## Output

A project folder with all research artifacts:

```
/viability/{project-name}/
  ├── phase-1-problem-validation.md
  ├── phase-2-persona-deep-dive.md
  ├── phase-2-persona-card.html
  ├── phase-3-competitive-landscape.md
  ├── phase-3-competitive-data.xlsx
  ├── phase-4-differentiation.md
  ├── phase-5-business-model.md
  ├── phase-6-technical-feasibility.md
  ├── viability-scorecard.xlsx
  ├── viability-scorecard.html
  └── summary.md
```

Where it's saved:
- **Claude Code**: In the current working directory under `viability/{project-name}/`
- **claude.ai**: Under `/mnt/user-data/outputs/viability/{project-name}/`

---

## Execution Modes

### Mode A — Guided (Interactive)

Run one phase at a time. After each phase:
1. Present key findings to the user
2. Ask if they want to adjust anything before proceeding
3. Move to the next phase only after confirmation

Best for: first-time use, high-stakes ideas, ideas where the user has strong opinions.

Trigger phrases: "validate this idea", "guided analysis", "walk me through it", "step by step"

### Mode B — Full Run (Autonomous)

Run all 6 phases back-to-back with minimal interruption:
1. Run Phases 1-6 sequentially, using each phase's output as input for the next
2. Generate all outputs (reports, spreadsheets, scorecard, persona card)
3. Present the complete analysis with the scorecard decision at the end
4. Ask for review and adjustments

Best for: quick validation, comparing multiple ideas, experienced users.

Trigger phrases: "full run", "quick validation", "just run it", "autonomous"

**Default**: If the user doesn't specify, ask which mode they prefer.

---

## Workflow

### Step 0 — Setup

1. Derive a slug from the idea (e.g., "nutrition-app", "tour-management")
2. Create the output folder: `viability/{slug}/`
3. Run `scripts/build_spreadsheets.py {output_folder}` to generate blank spreadsheet templates
4. Copy `assets/phase-report-template.md` into the folder for reference

### Step 1 — Gather Idea Context

Before running phases, collect minimum viable context:
- **What problem does this solve?** (1-3 sentences)
- **Who has this problem?** (target user/customer)
- **Any domain expertise the user has?** (check user's profile/context if available)

In Claude Code: check for a business profile or CLAUDE.md that contains the user's background. Use it to pre-fill founder-market fit context.

### Step 2 — Run Research Phases

Read `references/framework.md` for the full prompt templates and methodology.

For each phase (1 through 6):

1. **Adapt the prompt template** from `references/framework.md` with the user's specific idea details and findings from previous phases
2. **Execute research** using web search, web fetch, and reasoning
3. **Write the phase report** using the shared template structure from `assets/phase-report-template.md`:
   - Findings Summary (required)
   - Evidence & Sources (required)
   - Key Quotes & Signals (when relevant)
   - Quantitative Data (when relevant)
   - Risks & Red Flags (required)
   - Confidence Rating with justification (required)
   - Input for Next Phase (required)
4. **Save** as `phase-X-{name}.md` in the output folder

### Phase-Specific Extra Outputs

**After Phase 2 (Persona Deep Dive)**:
- Read `assets/persona-card.html`
- Generate a filled-in persona card HTML with the discovered persona data
- Save as `phase-2-persona-card.html` in the output folder

**After Phase 3 (Competitive Landscape)**:
- Populate `phase-3-competitive-data.xlsx` (generated in Step 0) with:
  - Competitor Comparison sheet: name, type, pricing, features, weaknesses, ratings
  - Gap Analysis sheet: identified market gaps with evidence
  - Pricing Landscape sheet: competitor pricing tiers
- Save the updated spreadsheet

### Step 3 — Score and Decide

After all 6 phases are complete:

1. **Auto-score all 10 dimensions** based on research findings:

   | Dimension | Primary Evidence Source |
   |-----------|----------------------|
   | Problem severity | Phase 1: frequency, emotional intensity, financial impact |
   | Persona clarity | Phase 2: specificity of persona, findability, audience size |
   | Market size | Phase 2 + 3: addressable audience numbers, market data |
   | Competitive gap | Phase 3: identified gaps, competitor weaknesses |
   | Differentiation | Phase 4: defensibility, unfair advantage strength |
   | Business model | Phase 5: unit economics, customer count feasibility |
   | Acquisition channel | Phase 5 + 2: reachability, cost estimates |
   | Technical feasibility | Phase 6: showstoppers, timeline, stack fit |
   | Founder-market fit | Phase 2 + user context: domain expertise, connections |
   | Solo founder viability | Phase 5 + 6: bottleneck analysis, support burden |

2. **For each score, provide a 1-sentence justification** explaining why that score and not higher or lower

3. **Calculate weighted total** (weights defined in framework.md)

4. **Determine decision**: Strong Go / Conditional Go / Pivot / Kill

5. **Generate outputs**:
   - Fill `viability-scorecard.xlsx` with scores, justifications, and formulas
   - Generate filled `viability-scorecard.html` from `assets/scorecard.html` with actual data
   - Write `summary.md` — one-page executive summary:
     - Project name and one-line description
     - Score: X/110 → Decision
     - Top 3 strongest dimensions with brief why
     - Top 3 weakest dimensions with brief why
     - Key risks if proceeding
     - Recommended next step

### Step 4 — Present Results

**Guided mode**: Present the scorecard and summary, ask if the user wants to adjust any scores or re-run specific phases.

**Full-run mode**: Present the complete folder of outputs with the summary and scorecard decision front-and-center.

In both modes:
- If **Go** or **Conditional Go**: remind the user to proceed to the SaaS Business Intake Questionnaire with their validated data
- If **Pivot**: suggest which phases to re-run after reformulating
- If **Kill**: acknowledge the decision, remind them to archive the research

---

## Scoring Calibration Guide

To keep auto-scoring consistent across analyses:

### Score = 1 (Red Flag)
- Phase found active counter-evidence (e.g., dominant competitor with no gap, problem debunked)
- Data contradicts the hypothesis

### Score = 2 (Weak)
- Minimal supporting evidence found
- Research was inconclusive or based on thin data

### Score = 3 (Acceptable)
- Some supporting evidence, but also some concerns
- Average market conditions, nothing stands out

### Score = 4 (Good)
- Clear supporting evidence from multiple sources
- Above-average conditions, identifiable advantages

### Score = 5 (Excellent)
- Strong, multi-source evidence with high confidence
- Exceptional conditions (e.g., founder has deep domain access, no direct competitors, validated demand)

**Bias toward conservative scoring.** It's better to score a 3 and proceed cautiously than score a 4 and miss risks. The user can always override upward.

---

## Error Handling

- **Web search fails for a phase**: Note limited evidence in the report, lower confidence rating, flag in risks. Do NOT invent data.
- **Not enough competitors found (Phase 3)**: This is itself a signal — either the market is too niche or the search terms need adjustment. Try broader terms before concluding.
- **Idea is too vague to research**: Ask the user for more specifics. Don't proceed with assumptions.
- **Conflicting evidence**: Present both sides in the report. Score conservatively. Flag in risks.

---

## Quality Checklist

Before delivering the final analysis, verify:

- [ ] All 6 phase reports saved with consistent template structure
- [ ] Every phase report has Evidence & Sources with actual links
- [ ] Phase 2 persona card HTML is filled with research data
- [ ] Phase 3 spreadsheet has competitor data populated
- [ ] All 10 scorecard dimensions scored with justifications
- [ ] Scorecard total calculated correctly (verify arithmetic)
- [ ] Decision matches the score range in the decision matrix
- [ ] Summary.md is a standalone one-page document
- [ ] No fabricated data — all claims traceable to research
- [ ] Input for Next Phase sections chain correctly between phases
