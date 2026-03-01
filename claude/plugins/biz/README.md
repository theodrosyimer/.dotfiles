# Biz

A Claude Code plugin for solo founders that turns business ideas into launch-ready plans — validation, naming, marketing, legal, and growth strategy.

## What's Inside

### Skills (10)

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| **onboarding** | First-time setup wizard | Just installed the plugin |
| **business-profile** | Generate your business profile | Setting up or updating your background |
| **tech-preferences** | Generate your tech stack preferences | Setting up or updating your stack |
| **viability-analysis** | 6-phase idea validation | Before building anything new |
| **saas-intake** | MVP business questionnaire | Planning a validated product |
| **saas-scaleup** | Growth strategy questionnaire | Product has traction, ready to scale |
| **product-naming** | Naming + positioning + marketing | Need a name, brand, or go-to-market plan |
| **email-marketing** | Email sequences & automation | Building customer communication |
| **legal-guide** | French micro-entreprise reference | Legal, tax, compliance questions |
| **github-strategy** | GitHub org & repo management | Setting up dev infrastructure |

### Subagents (4)

| Agent | Skills | Specialization |
|-------|--------|---------------|
| **researcher** | viability-analysis | Idea validation, market research |
| **marketer** | product-naming, email-marketing | Naming, positioning, email sequences |
| **ops** | legal-guide, github-strategy | Legal setup, dev infrastructure |
| **builder** | tech-preferences, saas-intake, saas-scaleup | Technical decisions, project planning |

### Commands (1)

| Command | Purpose |
|---------|---------|
| **`/launch`** | Start, resume, or check progress on a project. Orchestrates the full workflow with persistent tracking. |

```
/launch                        → List all projects
/launch project1              → Start or resume a project
/launch project1 status       → Detailed progress
/launch project1 skip 4       → Skip a step
/launch project1 notes 2 "…"  → Add notes to a step
```

## Installation

```bash
# From GitHub (when published)
/plugin install biz@your-marketplace

# Local development
claude --plugin-dir /path/to/biz
```

## Quick Start

1. **Run onboarding**: Say "set up the toolkit" or "onboarding"
2. **Generate profiles**: The onboarding walks you through business + tech interviews
3. **Start using skills**: Reference them by name or let Claude invoke them automatically

## Recommended Workflow

Run `/launch <project-codename>` to start. Progress is tracked across sessions.

```
/launch myproject
  → Step 1: viability-analysis (validate before building)
  → Step 2: saas-intake (detailed planning if validated)
  → Step 3: product-naming (name and position)
  → Step 4: email-marketing (customer communication)
  → Step 5: legal-guide + github-strategy (set up operations)
  → Step 6: 🔨 Build & ship your product
  → Step 7: saas-scaleup (when you have traction)
```

Each step updates `projects/<codename>/progress.md`. You can pause, skip steps, resume days later, and work on multiple projects independently.

## Profile System

Two skills generate personalized profile documents:

- `profiles/business-profile.md` — your background, goals, constraints
- `profiles/tech-preferences.md` — your technology stack and preferences

Other skills read these profiles to personalize their output. Without profiles, skills still work but give more generic guidance.

## Output Files

Every file the plugin generates, organized by source.

### Global (shared across projects)

```
profiles/
├── business-profile.md          ← onboarding / business-profile skill
└── tech-preferences.md          ← onboarding / tech-preferences skill
```

### Per Project

```
projects/{codename}/
├── progress.md                  ← /launch command (persistent state tracker)
├── intake-questionnaire.md      ← saas-intake (step 2)
├── naming-decisions.md          ← product-naming (step 3)
├── email-sequences.md           ← email-marketing (step 4)
├── legal-notes.md               ← legal-guide (step 5)
├── github-setup.md              ← github-strategy (step 5)
├── scaleup-questionnaire.md     ← saas-scaleup (step 7)
└── viability/                   ← viability-analysis (step 1)
    ├── phase-1-problem-validation.md
    ├── phase-1-problem-validation.pdf
    ├── phase-2-persona-deep-dive.md
    ├── phase-2-persona-deep-dive.pdf
    ├── phase-2-persona-card.html
    ├── phase-3-competitive-landscape.md
    ├── phase-3-competitive-landscape.pdf
    ├── phase-3-competitive-data.xlsx
    ├── phase-4-differentiation.md
    ├── phase-4-differentiation.pdf
    ├── phase-5-business-model.md
    ├── phase-5-business-model.pdf
    ├── phase-6-technical-feasibility.md
    ├── phase-6-technical-feasibility.pdf
    ├── viability-scorecard.xlsx
    ├── viability-scorecard.html
    └── summary.md
```

## Using with Agent Teams

This plugin is agent-team-ready. You can use subagents for parallel work:

```
"Run viability analysis on my nutrition app idea while the marketer
prepares naming options based on the intake questionnaire."
```

Agent team members automatically load the plugin's skills.

## License

MIT
