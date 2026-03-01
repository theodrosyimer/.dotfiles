# Viability Analysis Skill

Validate any SaaS or app idea **before writing a single line of code**. This skill runs 6 structured research phases using AI + web search, then delivers a weighted Go/No-Go scorecard with all supporting evidence.

## What It Does

You describe an idea. Claude researches it across 6 dimensions, produces structured reports, and tells you whether to build it, pivot, or kill it — backed by evidence, not gut feeling.

### The 6 Research Phases

| Phase | Question It Answers |
|-------|-------------------|
| 1. Problem Validation | Is the pain real? Do people complain about it and pay to solve it? |
| 2. Persona Deep Dive | Who feels it most? Can you find and reach them? |
| 3. Competitive Landscape | What exists? Where are the gaps? |
| 4. Differentiation | Why would someone choose your solution? |
| 5. Business Model | Do the numbers work for a solo bootstrapped founder? |
| 6. Technical Feasibility | Can you build it with your stack? Any showstoppers? |

### What You Get

```
viability/{your-project}/
├── phase-1-problem-validation.md       ← Research report with evidence + sources
├── phase-1-problem-validation.pdf      ← Styled PDF report (dark/light mode)
├── phase-2-persona-deep-dive.md
├── phase-2-persona-deep-dive.pdf
├── phase-2-persona-card.html           ← Visual persona card
├── phase-3-competitive-landscape.md
├── phase-3-competitive-landscape.pdf
├── phase-3-competitive-data.xlsx       ← Sortable competitor comparison spreadsheet
├── phase-4-differentiation.md
├── phase-4-differentiation.pdf
├── phase-5-business-model.md
├── phase-5-business-model.pdf
├── phase-6-technical-feasibility.md
├── phase-6-technical-feasibility.pdf
├── viability-scorecard.xlsx            ← Weighted scores with auto-calculated decision
├── viability-scorecard.html            ← Interactive radar chart
└── summary.md                          ← One-page Go/No-Go with key findings
```

---

## Installation

Drop the `viability-analysis/` folder into your Claude Code skills directory:

```bash
# Example — adjust the path to your skills location
cp -r viability-analysis/ ~/.claude/skills/viability-analysis/
```

**Dependency**: The spreadsheet generator requires `openpyxl`:

```bash
pip install openpyxl
```

---

## Usage

### Quick Start

Just tell Claude about your idea. Any of these will trigger the skill:

- *"I have an idea for a nutrition app that scans ingredients and suggests healthy meals. Should I build this?"*
- *"Validate this SaaS idea: tour management automation for musicians"*
- *"Run a viability analysis on a freelancer invoicing tool for the French market"*

Claude will ask you to pick an execution mode, then start researching.

### Execution Modes

#### Guided (Interactive)

Claude runs one phase at a time, presents findings, and waits for your confirmation before moving on. Best for high-stakes ideas or when you want to steer the research.

```
"Validate this idea — guided"
"Walk me through a viability analysis for [idea]"
```

#### Full Run (Autonomous)

Claude runs all 6 phases back-to-back, produces every output, then presents the complete analysis. Best for quick validation or comparing multiple ideas.

```
"Quick validation: [idea]"
"Run a full viability analysis on [idea]"
```

If you don't specify, Claude will ask which mode you prefer.

### Trigger Phrases

Any of these (or similar) will activate the skill:

- "Should I build this?"
- "Validate this idea"
- "New SaaS idea"
- "Run step 0"
- "Is this worth building?"
- "Viability analysis"
- "Pre-build analysis"

---

## Understanding the Scorecard

### 10 Dimensions (Weighted)

| Dimension | Weight | Why It Matters |
|-----------|--------|---------------|
| Problem severity | ×3 | No real pain = no customers |
| Persona clarity | ×2 | Vague persona = can't market |
| Market size | ×2 | Too small = ceiling on growth |
| Competitive gap | ×3 | No gap = uphill battle |
| Differentiation | ×2 | No moat = commoditized |
| Business model | ×3 | Numbers don't work = dead end |
| Acquisition channel | ×2 | Can't reach them = can't sell |
| Technical feasibility | ×1 | You're technical, this rarely kills ideas |
| Founder-market fit | ×2 | Domain expertise = unfair advantage |
| Solo founder viability | ×2 | Can one person pull it off? |

### Scoring Scale

- **5** — Excellent, strong multi-source evidence
- **4** — Good, clear supporting evidence
- **3** — Acceptable, some evidence with concerns
- **2** — Weak, minimal or inconclusive evidence
- **1** — Red flag, counter-evidence found

### Decision Matrix

| Score | Decision | What To Do |
|-------|----------|-----------|
| **88-110** (80%+) | 🟢 Strong Go | Start building. Fill the SaaS Intake Questionnaire with your validated data. |
| **66-87** (60-79%) | 🟡 Conditional Go | Address weak dimensions first. Re-run those phases with deeper research. |
| **44-65** (40-59%) | 🟠 Pivot | The core has potential but needs rethinking. Revisit positioning or persona. |
| **Below 44** (<40%) | 🔴 Kill | Move on. Archive the research — markets change. |

---

## After the Analysis

### If Go → Next Step

Your validated research maps directly to the **SaaS Business Intake Questionnaire**:

| Viability Phase | Feeds Into |
|----------------|-----------|
| Phase 1: Problem Validation | Problem & Solution Definition |
| Phase 2: Persona Deep Dive | Target Market |
| Phase 3: Competitive Landscape | Market Analysis |
| Phase 4: Differentiation | Competitive Advantage + Positioning |
| Phase 5: Business Model | Business Model + Unit Economics |
| Phase 6: Technical Feasibility | Technical Approach |

You'll fill the intake questionnaire with **researched data, not assumptions**.

### If Kill → Archive

Save the analysis. Markets shift, timing matters. An idea that scores 40 today might score 75 in six months.

### If Pivot → Re-run

Identify the weakest phases, reformulate the idea to address those gaps, and re-run only the affected phases.

---

## Comparing Multiple Ideas

Run the skill on each idea separately, then compare scorecard totals:

```
Idea A: Nutrition App         → 78/110 🟡 Conditional Go
Idea B: Tour Management Tool  → 91/110 🟢 Strong Go
Idea C: Freelancer Invoicing  → 52/110 🟠 Pivot
```

This gives you an objective basis for prioritizing where to invest your time.

---

## Skill Structure

```
viability-analysis/
├── SKILL.md                              ← Workflow orchestration + scoring logic
├── references/
│   └── framework.md                      ← Full 6-phase prompt templates + methodology
├── assets/
│   ├── phase-report-template.md          ← Shared report structure for all phases
│   ├── persona-card.html                 ← Visual persona card template
│   └── scorecard.html                    ← Interactive radar chart template
└── scripts/
    ├── build_report.py                   ← PDF generator (dark/light, WCAG AA, accent colors)
    └── build_spreadsheets.py             ← Generates .xlsx templates with formulas
```

---

## Tips

- **Be specific about your idea** — "a task app" gives weak results. "A task management tool for French freelance designers who work with international clients" gives strong results.
- **Guided mode for your first run** — it helps you understand the process and catch any research gaps.
- **Full-run mode once you trust it** — faster, good for screening multiple ideas quickly.
- **Don't ignore the scorecard** — it exists to protect your time. A few hours of research saves months of wasted development.
- **Re-run when markets change** — an archived Kill analysis is worth revisiting 6-12 months later.
