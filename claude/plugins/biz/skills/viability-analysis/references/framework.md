# Pre-Build Viability Analysis Framework

## Purpose

This framework answers one question before you write a single line of code: **Should I build this?**

It sits as **Step 0** in your SaaS workflow:

```
Idea → [THIS] Viability Analysis → SaaS Intake Questionnaire → Build → Scale-Up Questionnaire
```

Most projects fail not because of bad code, but because of bad assumptions. This framework uses a structured sequence of AI-assisted research prompts to validate (or kill) an idea in a few hours, not weeks.

## How to Use

1. **Run each research phase sequentially** — each phase feeds the next
2. **Copy the prompt templates**, adapt the `[BRACKETS]` to your idea, run with Claude + web search
3. **Save phase outputs** into the project folder (see Output Specification below)
4. **Complete the Viability Scorecard** at the end to make a Go/No-Go decision
5. **If Go** → proceed to SaaS Business Intake Questionnaire with pre-validated data

**Time investment**: 2-4 hours for a thorough analysis

## Output Specification

Each viability analysis produces a project folder with all research artifacts.

### Folder Structure

```
/viability/{project-name}/
  ├── phase-1-problem-validation.md
  ├── phase-2-persona-deep-dive.md
  ├── phase-2-persona-card.html              ← visual persona card
  ├── phase-3-competitive-landscape.md
  ├── phase-3-competitive-data.xlsx          ← sortable competitor comparison
  ├── phase-4-differentiation.md
  ├── phase-5-business-model.md
  ├── phase-6-technical-feasibility.md
  ├── viability-scorecard.xlsx               ← auto-calculated weighted scores
  ├── viability-scorecard.html               ← interactive radar chart + decision
  └── summary.md                             ← final Go/No-Go with key findings
```

### Markdown Report Template (Shared Across All Phases)

Each phase report uses the same flexible structure. All sections are present but content depth varies by phase — write what's relevant, skip what's not.

```markdown
# Phase [X]: [Phase Name]
## Project: [Project Name]
## Date: [YYYY-MM-DD]

---

## Findings Summary
[Core discoveries from this phase — the headline takeaways]

## Evidence & Sources
[Links, data points, search results that support findings]

## Key Quotes & Signals
[Direct quotes from forums, reviews, users that illustrate the pain/opportunity]

## Quantitative Data
[Numbers, statistics, market sizes, pricing data — anything measurable]

## Risks & Red Flags
[What concerns you? What could invalidate this phase's findings?]

## Confidence Rating
[ ] High | [ ] Medium | [ ] Low
[Brief justification for the rating]

## Input for Next Phase
[What specific findings feed into the next phase's research?
What questions emerged that the next phase should answer?]
```

### Special Outputs

| Phase | Extra Output | Description |
|-------|-------------|-------------|
| Phase 2 | `persona-card.html` | Visual persona card: name, role, pain points, budget, channels, key quotes |
| Phase 3 | `competitive-data.xlsx` | Structured competitor comparison: features, pricing, ratings, weaknesses |
| Final | `viability-scorecard.xlsx` | Weighted scorecard with auto-calculated totals and decision |
| Final | `viability-scorecard.html` | Interactive radar chart showing all 10 dimensions + Go/No-Go threshold |
| Final | `summary.md` | One-page executive summary pulling key conclusions from all phases |

---

## Phase 1: Problem Validation

### Why This Matters

Most founders fall in love with their solution. This phase forces you to fall in love with the problem first. A real problem has evidence: people complain about it, pay to solve it, or waste time working around it.

### Prompt Template

```
I'm exploring a business idea in the [INDUSTRY/DOMAIN] space.

The problem I think exists: [DESCRIBE THE PROBLEM IN 2-3 SENTENCES]

The people I think have this problem: [DESCRIBE TARGET USERS]

Help me validate whether this is a real, painful problem:

1. Search for evidence that people actively complain about this problem
   (forums, Reddit, Twitter/X, review sites, Quora)
2. What workarounds do people currently use? How painful are those workarounds?
3. Are people already paying money to solve this or a closely related problem?
4. What's the frequency of this problem — daily frustration, weekly annoyance, or rare occurrence?
5. Is this problem getting worse over time (growing market) or being solved (shrinking opportunity)?

Be brutally honest. If the evidence is weak, tell me.
```

### What to Look For

- **Strong signal**: Multiple independent sources confirming the pain. People describing emotional frustration, wasted time, or lost money
- **Weak signal**: Only your own experience confirms it. No one is paying to solve it. Workarounds are "good enough"
- **Kill signal**: The problem exists but is too niche, too infrequent, or people don't care enough to pay

### Findings

**Evidence of real pain**: [What did you find? Quotes, links, data]

**Current workarounds people use**: [List them — these are your indirect competitors]

**Frequency & severity**: [Daily/weekly/monthly? Annoying/costly/critical?]

**Market trajectory**: [Growing/stable/shrinking?]

**Phase 1 Confidence**: [ ] High — clear evidence of pain | [ ] Medium — some evidence | [ ] Low — mostly assumptions

---

## Phase 2: Target Persona Deep Dive

### Why This Matters

"Everyone" is not a customer. This phase identifies who feels the pain most acutely, who has budget to pay, and who is reachable. Your first 100 customers will come from one specific segment — find it.

### Prompt Template

```
Based on the problem: [PROBLEM FROM PHASE 1]

Help me identify and deeply understand the ideal first customer:

1. Who experiences this problem MOST intensely?
   (Job title, company size, industry, demographics, daily workflow)
2. What is their typical day like? When does this problem hit them?
3. What is the financial impact of this problem on them?
   (Time wasted per week, money lost, opportunities missed)
4. Where do these people hang out online?
   (Communities, forums, social platforms, publications they read)
5. What language do they use to describe this problem?
   (Search terms, complaints, how they'd explain it to a colleague)
6. What's their budget authority? Can they buy a tool themselves
   or do they need approval?
7. How many of these people exist?
   (Estimate the addressable audience size)

If there are multiple segments, rank them by:
pain severity × ability to pay × ease of reaching them
```

### What to Look For

- **Strong signal**: You can name specific job titles, communities, and publications. The persona's language matches real search queries
- **Weak signal**: The persona is vague ("small business owners") or you can't find where they congregate
- **Kill signal**: The people with the problem can't pay, or the segment is too small to build a business

### Findings

**Primary Persona**: [Job title, context, daily reality]

**Pain intensity for this persona**: [Quantify: hours/week wasted, €/month lost]

**Where to find them**: [Specific communities, platforms, publications]

**Their vocabulary**: [Exact words they use to describe the problem — these become your marketing copy and SEO keywords]

**Addressable audience size**: [Number estimate with source]

**Budget & buying power**: [Can they self-serve purchase? What price range?]

**Phase 2 Confidence**: [ ] High — specific, findable persona | [ ] Medium — broad but directional | [ ] Low — can't identify who exactly

---

## Phase 3: Competitive Landscape Analysis

### Why This Matters

No competition = no market (or you haven't looked hard enough). Competition validates demand. Your job is to find gaps — underserved segments, missing features, bad UX, wrong pricing, or ignored markets.

### Prompt Template

```
I want to solve [PROBLEM] for [PERSONA FROM PHASE 2].

Do a comprehensive competitive analysis:

1. **Direct competitors**: Tools/products that solve this exact problem.
   For each, find: pricing, target market, key features, user reviews
   (especially negative reviews — what do users complain about?)

2. **Indirect competitors**: Alternative approaches people use
   (spreadsheets, manual processes, hiring someone, other tool categories)

3. **Adjacent solutions**: Products that solve a related problem and
   could easily add this feature

4. **Market gaps**: Based on competitor weaknesses and user complaints,
   where is the opportunity? What are competitors NOT doing well?

5. **Pricing landscape**: What's the typical price range for solutions
   in this space? Is there room for a premium or budget positioning?

6. **Competitor traction signals**: Look for employee count, funding,
   social media following, review volume — indicators of market validation

For each direct competitor, rate:
- Product quality (from reviews): 1-5
- Pricing accessibility: 1-5
- Target market overlap with my persona: 1-5
```

### What to Look For

- **Strong signal**: Competitors exist and are growing, but have clear, consistent complaints. There's a gap you can fill (underserved segment, bad UX, missing feature, wrong market)
- **Weak signal**: Very crowded space with no obvious gap. Or zero competitors (why not?)
- **Kill signal**: A dominant player with great product, low pricing, and high satisfaction. Or a well-funded startup just launched exactly what you'd build

### Findings

**Direct Competitors**:

| Competitor | Pricing | Strengths | Weaknesses (from reviews) | Market Overlap |
|-----------|---------|-----------|--------------------------|----------------|
| [Name 1]  |         |           |                          |                |
| [Name 2]  |         |           |                          |                |
| [Name 3]  |         |           |                          |                |

**Indirect Competitors / Workarounds**: [List them]

**Adjacent Threats**: [Products that could add this feature easily]

**Identified Gaps**: [Where competitors fail — this is your opportunity]

**Pricing Landscape**: [Range and sweet spot]

**Phase 3 Confidence**: [ ] High — clear gap identified | [ ] Medium — opportunity exists but competitive | [ ] Low — no gap or too crowded

---

## Phase 4: Differentiation & Positioning

### Why This Matters

You've confirmed the problem is real, identified who feels it, and mapped the competition. Now: why would someone choose YOUR solution? If you can't articulate a clear, compelling difference, you'll compete on price — and lose as a solo founder.

### Prompt Template

```
Context:
- Problem: [PROBLEM]
- Target persona: [PERSONA]
- Key competitors: [TOP 3 COMPETITORS + THEIR WEAKNESSES]
- Market gaps identified: [GAPS FROM PHASE 3]

Help me develop a differentiation strategy:

1. Based on the competitor weaknesses and market gaps, what are 3 possible
   positioning angles I could take? For each, explain:
   - The core differentiator
   - Why it matters to the target persona
   - How defensible it is (can competitors copy it easily?)

2. For each positioning angle, draft a one-line value proposition
   in this format: "[Product] helps [persona] [achieve outcome]
   by [unique approach], unlike [alternative] which [limitation]."

3. What would an unfair advantage look like for each positioning?
   (Domain expertise, technology, distribution, data, community)

4. Which positioning is strongest for a solo bootstrapped founder
   who needs to reach profitability quickly?

Consider my constraints:
- Solo founder, bootstrapping
- TypeScript/React stack (fast development, cross-platform potential)
- [ANY DOMAIN EXPERTISE YOU HAVE]
- Target: €4,000/month MRR initially
```

### What to Look For

- **Strong signal**: One positioning angle feels obvious and defensible. You have a genuine unfair advantage (domain expertise, unique technology approach, underserved market access)
- **Weak signal**: Differentiation is "better UX" or "cheaper" — these are temporary advantages
- **Kill signal**: You can't articulate why someone would switch from an existing solution to yours

### Findings

**Chosen Positioning**: [Which angle and why]

**Value Proposition (one sentence)**: [Your "helps X achieve Y by Z unlike W" statement]

**Unfair Advantage**: [What makes this defensible for you specifically?]

**Why a customer would switch**: [The compelling reason to leave current solution]

**Phase 4 Confidence**: [ ] High — clear, defensible position | [ ] Medium — differentiated but fragile | [ ] Low — "me too" product

---

## Phase 5: Business Model Sanity Check

### Why This Matters

A real problem with a great solution still fails if the numbers don't work. This phase checks whether you can build a sustainable business — not just a product — given your constraints as a solo bootstrapped founder.

### Prompt Template

```
Context:
- Solution: [YOUR SOLUTION + POSITIONING FROM PHASE 4]
- Target persona: [PERSONA]
- Competitor pricing: [PRICING LANDSCAPE FROM PHASE 3]
- My constraint: solo bootstrapped founder, target €4,000/month MRR

Help me sanity-check the business model:

1. **Pricing**: Given competitor pricing and persona's budget,
   what's a realistic monthly price point?
   What tier structure makes sense?

2. **Customer count needed**: At that price, how many paying customers
   do I need for €4,000/month? Is that realistic for this market?

3. **Acquisition cost estimate**: Based on where the persona hangs out
   (from Phase 2), what would customer acquisition likely cost?
   (Content marketing = time, paid ads = money, outreach = time)

4. **Churn reality check**: For this type of product and persona,
   what's a realistic monthly churn rate?
   What does that mean for growth sustainability?

5. **Time to revenue**: Realistically, with [X hours/week] available
   for development, how long to MVP → first paying customer → €4,000 MRR?

6. **Solo founder feasibility**: Can one person realistically build,
   market, sell, AND support this product? What breaks first?

Be conservative in estimates. I'd rather kill a bad idea than
discover problems after months of building.
```

### What to Look For

- **Strong signal**: Reasonable price point, achievable customer count, multiple acquisition channels available, manageable as solo founder initially
- **Weak signal**: Need 1000+ customers at low price, high acquisition cost, or requires heavy sales process
- **Kill signal**: Numbers don't work without funding. Or requires full-time support staff before profitability

### Findings

**Proposed pricing**: [€/month per tier]

**Customers needed for €4K MRR**: [Number and feasibility assessment]

**Primary acquisition channel**: [How you'll get customers and estimated cost]

**Estimated churn**: [%/month and impact on growth]

**Time to €4K MRR (realistic)**: [Months, including build time]

**Solo founder bottleneck**: [What breaks first as you scale?]

**Phase 5 Confidence**: [ ] High — numbers work | [ ] Medium — tight but possible | [ ] Low — numbers don't add up

---

## Phase 6: Quick Technical Feasibility

### Why This Matters

Brief sanity check on whether you can actually build this with your stack and constraints. Not a full technical plan — that comes in the SaaS Intake Questionnaire. Just enough to catch showstoppers.

### Prompt Template

```
I want to build [SOLUTION DESCRIPTION] as a [web app / mobile app / hybrid].

Quick technical feasibility check given my stack
(TypeScript, React/React Native, NestJS, PostgreSQL):

1. Are there any major technical challenges or unknowns?
   (AI/ML requirements, complex algorithms, real-time needs,
   third-party API dependencies, data processing at scale)

2. Are there critical third-party services I'd depend on?
   What's the risk of those dependencies?

3. Rough estimate: is this a 1-month MVP, 3-month MVP, or 6-month+ MVP
   for a solo full-stack developer?

4. Any regulatory or compliance showstoppers?
   (Health data, financial data, children's data, etc.)

5. What's the hardest technical problem to solve, and is it core
   to the value proposition or peripheral?

Keep it brief — I just need to know if there are dealbreakers.
```

### Findings

**Technical showstoppers**: [Any? If yes, describe]

**Critical dependencies**: [Third-party services and their risk]

**Estimated MVP timeline**: [1/3/6 months and key assumptions]

**Regulatory concerns**: [Any compliance requirements?]

**Hardest technical challenge**: [What is it and is it core or peripheral?]

**Phase 6 Confidence**: [ ] High — buildable with my stack | [ ] Medium — some unknowns to resolve | [ ] Low — major technical risk

---

## Viability Scorecard

Rate each dimension based on your research findings. Be honest — the scorecard only helps if it reflects reality.

### Scoring Guide

- **1** = Red flag / serious concern
- **2** = Weak / uncertain
- **3** = Acceptable / average
- **4** = Good / above average
- **5** = Excellent / strong conviction

### Score Sheet

| # | Dimension | Score (1-5) | Weight | Weighted Score | Notes |
|---|-----------|-------------|--------|----------------|-------|
| 1 | **Problem severity** — Is the pain real and frequent? | [ ] | ×3 | [ ] | |
| 2 | **Persona clarity** — Can you name and find the buyer? | [ ] | ×2 | [ ] | |
| 3 | **Market size** — Enough potential customers? | [ ] | ×2 | [ ] | |
| 4 | **Competitive gap** — Is there a real opening? | [ ] | ×3 | [ ] | |
| 5 | **Differentiation** — Why you, why now? | [ ] | ×2 | [ ] | |
| 6 | **Business model** — Do the numbers work? | [ ] | ×3 | [ ] | |
| 7 | **Acquisition channel** — Can you reach customers affordably? | [ ] | ×2 | [ ] | |
| 8 | **Technical feasibility** — Can you build it with your stack? | [ ] | ×1 | [ ] | |
| 9 | **Founder-market fit** — Do you have relevant expertise or access? | [ ] | ×2 | [ ] | |
| 10 | **Solo founder viability** — Can one person pull this off? | [ ] | ×2 | [ ] | |

**Total Weighted Score**: [ ] / 110

### Decision Matrix

| Score Range | Decision | Action |
|-------------|----------|--------|
| **88-110** (80%+) | 🟢 **Strong Go** | Proceed to SaaS Intake Questionnaire immediately |
| **66-87** (60-79%) | 🟡 **Conditional Go** | Address weak areas before committing. Re-run weak phases with deeper research |
| **44-65** (40-59%) | 🟠 **Pivot** | The core idea has potential but needs significant rethinking. Revisit positioning, persona, or problem definition |
| **Below 44** (<40%) | 🔴 **Kill** | Save your time. Move to next idea. Keep the research — market conditions change |

### Final Assessment

**Total Score**: [ ] / 110 → **Decision**: [ ]

**Strongest dimensions**: [What gives you most confidence?]

**Weakest dimensions**: [What concerns you most?]

**Key risks to monitor if proceeding**: [Top 2-3 risks]

**Pivot options if main approach fails**: [Alternative angles from your research]

---

## Post-Analysis: Next Steps

### If Go → SaaS Intake Questionnaire

Transfer your validated findings into the SaaS Business Intake Questionnaire:

| Viability Phase | Maps to Intake Section |
|----------------|----------------------|
| Phase 1: Problem Validation | Problem & Solution Definition |
| Phase 2: Persona Deep Dive | Target Market |
| Phase 3: Competitive Landscape | Market Analysis |
| Phase 4: Differentiation | Competitive Advantage + Brand & Positioning |
| Phase 5: Business Model | Business Model + Unit Economics |
| Phase 6: Technical Feasibility | Technical Approach |

You'll now fill the intake questionnaire with **researched data, not assumptions**.

### If Kill → Archive & Move On

- Save this completed analysis — markets change, timing matters
- Extract any reusable persona or market research for future ideas
- Move to next idea and run this framework again

### If Pivot → Re-run Specific Phases

- Identify which phases scored lowest
- Reformulate the idea addressing those weaknesses
- Re-run only the affected phases (and downstream phases)
- Re-score

---

*This framework is document 10 in your Business Project Knowledge Base. Run it for every new idea before committing to build. A few hours of research saves months of wasted development.*
