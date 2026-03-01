---
name: saas-intake
description: >
  Guided SaaS MVP business intake questionnaire. Use when the user wants to plan a new SaaS product,
  document a project idea, fill out a business plan, or prepare for building an MVP.
  Best used AFTER running viability-analysis to validate the idea.
  Walks through problem definition, target market, competitive analysis, business model,
  technical approach, and marketing strategy. Generates a completed questionnaire document.
---

# SaaS Business Intake Questionnaire — Guided Workflow

## Purpose

Walk the user through a comprehensive business intake questionnaire for a new SaaS/app project. The completed document becomes the reference for all project decisions — naming, marketing, technical, legal.

## Prerequisites

### Ideal Flow
```
viability-analysis (validated idea) → THIS (detailed planning) → build
```

If the user hasn't run viability-analysis, mention it:
> "Have you validated this idea yet? The viability-analysis skill can help you test assumptions before investing time in detailed planning. Want to run that first, or proceed with the intake?"

Don't block them — some users prefer to plan first and validate later.

## Profile Integration

If `profiles/business-profile.md` exists, **pre-fill** relevant sections:
- Personal context (background, skills, time availability)
- Financial constraints (runway, budget)
- Technical preferences (stack, approach)
- Market focus (geography, language)

Tell the user: "I've pre-filled some sections from your profile. Review and adjust as needed."

If `profiles/tech-preferences.md` exists, pre-fill the Technical Approach section.

## Workflow

### How to Conduct the Interview

**Don't dump the entire questionnaire.** Walk through it section by section:

1. Present one section at a time
2. Ask 3-5 questions per section
3. Summarize their answers before moving on
4. Allow them to skip sections and come back
5. At the end, generate the complete document

### Section Order

#### Section 1: Project Overview
- Project codename (internal reference name)
- Current status (idea/research/MVP/beta/launch/optimization)
- When they started considering this idea
- Target launch timeline

#### Section 2: Problem & Solution
- **Primary problem**: What specific problem does this solve? (Be very specific)
- **Problem severity**: Nice-to-have → critical business problem
- **Who has this problem**: Describe the people/companies
- **Current workarounds**: How do people solve this today?
- **Why existing solutions fail**: What's wrong with current options?
- **Core solution**: One-sentence description
- **Top 3-5 features**: What matters most for MVP?
- **MVP scope**: Absolute minimum version that provides value
- **Future vision**: Where could this go in 2-3 years?

#### Section 3: Target Market
- **Customer type**: Consumers, SMBs, mid-market, enterprise, specific industry
- **Geographic focus**: Local, regional, global
- **Customer profile**: Detailed ideal customer description
- **Customer budget**: What size companies/budgets?
- **Daily frustrations**: What annoys them?
- **Business impact**: How does the problem affect their business?
- **Urgency**: How quickly do they need this solved?
- **Price sensitivity**: How budget-conscious are they?

#### Section 4: Market Analysis
- **Direct competitors**: Top 3 + their approach and weaknesses
- **Indirect competitors**: Alternative solutions people use
- **Market size**: How many potential customers?
- **Market trends**: Growing or shrinking? Why?
- **Unique differentiator**: What makes this different/better?
- **Defensible moats**: What prevents copying?
- **Technical advantages**: Any technical superiority?
- **Go-to-market advantages**: Distribution or marketing edges?

#### Section 5: Business Model
- **Revenue model**: Subscription, freemium, usage-based, one-time, transaction fees
- **Pricing strategy**: How much and why?
- **Free tier** (if applicable): What's included?
- **Pricing tiers**: Levels and what they include
- **Target MRR per customer**: €X/month
- **CAC target**: €X to acquire one customer
- **LTV estimate**: €X total value per customer
- **Break-even timeline**: How long to profitability?

#### Section 6: Technical Approach
- **Complexity**: Simple CRUD → very complex (AI/research)
- **Platform**: ⚠️ **Always ask**: Web, mobile, or hybrid?
  - Web → Next.js or TanStack Start?
  - Mobile → React Native (Expo) default
  - Hybrid → Which frameworks for each?
- **Development timeline**: How long to MVP?
- **Team requirements**: Solo or need help?
- **Third-party integrations**: What external services?
- **Data requirements**: What data stored/processed?
- **Scaling considerations**: What if 1000x users?

#### Section 7: Marketing & Distribution
- **Primary channels**: Content/SEO, social, paid ads, cold outreach, partnerships, referrals, events
- **Marketing budget**: Monthly spend capacity
- **Content strategy**: What content attracts customers?
- **Launch strategy**: How to announce and promote?
- **Sales model**: Self-service, inside sales, partner channel
- **Sales cycle**: How long from contact to purchase?

#### Section 8: Brand & Positioning
- **Brand personality**: Professional, friendly, innovative, trustworthy, etc.
- **Brand values**: What principles matter?
- **Tone of voice**: How should the brand sound?
- **Visual style**: Modern, classic, bold, minimalist
- **Name style preference**: Descriptive, abstract, invented, compound
- **Names admired**: Examples they like
- **Names disliked**: Examples to avoid
- **Domain preferences**: .com required? .fr? .io?

#### Section 9: Regulatory (if applicable)
- **Data handling**: What personal data collected?
- **Industry regulations**: Any specific rules?
- **Business licenses**: Special certifications needed?
- **Compliance**: GDPR, accessibility, security standards

### Step: Generate Document

After all sections complete, generate the filled questionnaire using the template at `templates/intake-questionnaire.md`. Save to the project directory:

```
projects/{project-codename}/intake-questionnaire.md
```

## Post-Completion

Suggest next steps based on what they've filled out:
- **Need a name** → "Run `product-naming` with this questionnaire as context"
- **Need emails** → "Run `email-marketing` to create your sequences"
- **Need legal setup** → "Check `legal-guide` for registration"
- **Need GitHub setup** → "Run `github-strategy` for your repo structure"
- **Ready to build** → "Your tech approach section is your development brief"

---

*This questionnaire is the foundation for all project decisions. Keep it updated as the project evolves.*
