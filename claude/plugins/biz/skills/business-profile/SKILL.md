---
name: business-profile
description: >
  Generate or update a business profile document through an interactive interview.
  Use when the user says "set up my profile", "create business profile", "update my background",
  "onboarding", or when another skill needs user context and profiles/business-profile.md doesn't exist.
  Produces a structured markdown profile covering technical background, business goals, market focus,
  constraints, and communication preferences. Saved to profiles/business-profile.md in the project root.
---

# Business Profile Generator

## Purpose

Interview the user to build a comprehensive business profile that other skills reference for personalized guidance. The output file (`profiles/business-profile.md`) is the single source of truth about the user's background, goals, and constraints.

## Workflow

### Step 1: Check for Existing Profile

```
profiles/business-profile.md
```

- If exists → ask if they want to **update** (edit specific sections) or **regenerate** (full interview)
- If missing → run full interview

### Step 2: Interactive Interview

Ask questions in **batches of 3-5** — don't dump everything at once. Adapt follow-ups based on answers.

#### Batch 1: Technical Background
- Primary programming languages and frameworks?
- Years of experience? Professional or self-taught?
- Development philosophy? (frontend-first, backend-first, full-stack simultaneous)
- Architecture preferences? (monolith, microservices, modular monolith)
- Key projects you've built? (brief descriptions)

#### Batch 2: Business Context
- Current business structure? (freelance, micro-entreprise, LLC, corporation, not started yet)
- Country and any relocation plans?
- Solo founder or team?
- Current revenue sources? (client work, products, employment)
- Available time per week for product development?

#### Batch 3: Market & Goals
- What industries/domains are you targeting?
- Geographic market focus? (local, regional, global)
- Language capabilities for products? (English, French, other)
- Financial targets? (monthly revenue goal, timeline)
- Exit strategy preference? (lifestyle business, build to sell, build to scale)

#### Batch 4: Constraints & Resources
- Financial runway? Monthly expenses?
- Funding approach? (bootstrap, investors, grants)
- Risk tolerance? (conservative, moderate, aggressive)
- Work-life balance priority?

#### Batch 5: Communication & Branding
- Documentation language preferences? (code comments, business docs, customer-facing)
- Industry connections or networks?
- Professional presence priorities? (GitHub, social media, industry events)

### Step 3: Generate Profile

Use the template structure from `templates/profile-template.md` as the output format. Fill every section with the user's answers. Mark sections they skipped as `[Not specified — update later]`.

### Step 4: Save

Write the completed profile to:

```
profiles/business-profile.md
```

Create the `profiles/` directory if it doesn't exist. Confirm the file path to the user.

## Output Format

Follow the structure in `templates/profile-template.md` exactly. This ensures consistency across users and allows other skills to parse predictable sections.

## Integration with Other Skills

Other skills check for `profiles/business-profile.md` to personalize their output:
- **product-naming**: Uses market focus, language strategy, brand preferences
- **legal-guide**: Uses country, business structure, revenue model
- **email-marketing**: Uses language preferences, brand tone, customer segments
- **saas-intake**: Pre-fills sections from profile data
- **viability-analysis**: Uses domain expertise for founder-market fit scoring
- **github-strategy**: Uses team situation, client work model

If the profile doesn't exist, skills still work — they just ask for context inline or provide generic guidance.

## Important Notes

- Keep the interview conversational, not like a form
- Skip questions that are clearly irrelevant (e.g., don't ask about relocation if they just said they're settled)
- Offer to explain WHY each batch matters ("This helps the naming skill suggest culturally appropriate names")
- If the user provides a wall of text about themselves, extract and organize it rather than re-asking
- The profile is a living document — encourage updates as their situation evolves
