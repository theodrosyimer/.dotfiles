---
name: onboarding
description: >
  First-time setup wizard for the SaaS Business Toolkit plugin.
  Use when the user says "get started", "set up toolkit", "onboarding",
  "first time setup", or when they've just installed the plugin.
  Walks through the complete system, generates both profiles, and explains available skills.
---

# SaaS Business Toolkit — Onboarding

## Purpose

Welcome new users, generate their profiles, and give them a clear map of what's available. This is the entry point for anyone who just installed the plugin.

## Workflow

### Step 1: Welcome & System Check

Greet the user and check what already exists:

```
profiles/business-profile.md    → exists?
profiles/tech-preferences.md    → exists?
```

Report what's found:
- **Both exist** → "You're already set up! Here's a recap of available skills." Skip to Step 4.
- **One exists** → "You have [X] but not [Y]. Let's fill in the gap." Run only the missing generator.
- **Neither exists** → "Welcome! Let's set up your profiles. Takes about 15-20 minutes."

### Step 2: Business Profile Generation

Invoke the `business-profile` skill workflow:
- Run the interactive interview (batched questions)
- Generate `profiles/business-profile.md`
- Confirm completion before moving on

### Step 3: Tech Preferences Generation

Invoke the `tech-preferences` skill workflow:
- Run the interactive interview (batched questions)
- Generate `profiles/tech-preferences.md`
- Confirm completion

### Step 4: System Overview

Present the available skills organized by workflow stage:

```
🔍 VALIDATE
   viability-analysis  — 6-phase research to validate ideas before building

📋 PLAN
   saas-intake         — Guided MVP questionnaire (fill after validation)
   saas-scaleup        — Growth phase planning (fill when you have traction)

🏗️ BUILD & LAUNCH
   product-naming      — Naming frameworks, positioning, landing pages, pricing
   email-marketing     — Welcome, re-engagement, conversion, transactional sequences
   github-strategy     — Org structure, repo naming, access control, client work

⚖️ LEGAL & OPS
   legal-guide         — French micro-entreprise: registration, tax, compliance

🔧 PROFILES
   business-profile    — Update your business background anytime
   tech-preferences    — Update your technical preferences anytime
```

### Step 5: Suggest Next Action

Based on their profile, suggest the most relevant next step:

- **Has a specific idea** → "Run `viability-analysis` to validate it before building"
- **Exploring ideas** → "Start with `viability-analysis` when you have a concept to test"
- **Already building** → "Fill out the `saas-intake` questionnaire for your active project"
- **Has traction** → "Use `saas-scaleup` to plan your growth strategy"
- **Needs legal setup** → "Check `legal-guide` for French micro-entreprise requirements"
- **Needs a name** → "Use `product-naming` for naming frameworks and marketing strategy"

### Step 6: Subagents (Optional — Mention Only If Relevant)

If the user seems like they'd benefit from parallel work:

> "This toolkit also includes specialized subagents you can delegate to:
> - **researcher** — runs viability analysis phases
> - **marketer** — handles naming and email sequences
> - **ops** — handles legal and GitHub setup
> - **builder** — handles technical decisions and intake questionnaires
>
> You can use these with Claude Code's subagent or agent team features."

## Important Notes

- Don't rush the interview — this is the foundation for everything else
- If the user gets impatient, offer to skip sections and fill them later
- Make it clear that profiles can be updated anytime
- Emphasize the workflow: **Validate → Plan → Build → Scale**
- The whole point is: other skills give better advice when they know the user
