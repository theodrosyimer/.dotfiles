---
name: saas-scaleup
description: >
  Growth-phase strategic planning for SaaS products with traction.
  Use when the user has a launched product and asks about scaling, growth strategy,
  fundraising, team expansion, enterprise features, international expansion,
  improving unit economics, reducing churn, or exit planning.
  Prerequisites: launched MVP with real customers and revenue data.
---

# SaaS Scale-Up Strategy — Guided Workflow

## Purpose

Walk the user through strategic planning for scaling a validated SaaS product. This questionnaire is for products that have launched, have real customers, and are ready to grow.

## Prerequisites

### Readiness Signals
Before using this skill, the user should have:
- MVP launched with real customers
- Product-market fit signals (retention, word-of-mouth, feature requests)
- Some recurring revenue
- Understanding of acquisition channels
- Completed `saas-intake` questionnaire for this product

If they don't have these yet:
> "This questionnaire is for products with traction. It sounds like you might benefit from the `saas-intake` questionnaire first, or if you're still validating, try `viability-analysis`."

## Workflow

Walk through sections one at a time. **This is a strategic conversation, not a form** — discuss trade-offs, challenge assumptions, suggest options.

### Section 1: Current Performance Baseline

Get the numbers first — everything else depends on these:
- Monthly Recurring Revenue (MRR)
- Total active customers
- Monthly growth rate (%)
- Actual Customer Acquisition Cost (CAC)
- Actual Customer Lifetime Value (LTV)
- LTV/CAC ratio (healthy = 3:1 or higher)
- Monthly churn rate (%)
- Average Revenue Per User (ARPU)
- Gross margin (%)
- Net revenue retention (%)

### Section 2: Growth Strategy

- **Geographic expansion**: More countries? Deeper in current market?
- **Customer segment expansion**: Larger customers? New verticals? New sizes?
- **Product expansion**: More features? New products? Platform/API? White-label?
- **Competitive positioning**: How do they want to be known?
- **Pricing evolution**: Can they justify premium pricing? How?

### Section 3: Financial Strategy

- **Revenue targets**: 12/24/36 month MRR targets
- **Profitability timeline**: When cash-flow positive?
- **Funding approach**: Bootstrap, angels, seed VC, revenue-based financing, grants
- **Use of funds** (if raising): % split across product, marketing, team, ops
- **Unit economics targets**: Target improvements for margins, retention, churn, ARPU

### Section 4: Technical Scalability

- **Current challenges**: Performance? Cost scaling? Security gaps? Tech debt?
- **Infrastructure strategy**: Multi-region? Enterprise security certs? DR planning?
- **Development process**: Automated testing? CI/CD? Code review? Monitoring?
- **Product roadmap**: Top 5 priorities for next 12 months
- **Integration strategy**: Key integrations, API plans, marketplace presence
- **Data strategy**: Analytics, BI, data export, compliance

### Section 5: Team & Organization

- **Current team size**
- **Roles needed**: Developers, DevOps, PM, designer, marketing, sales, CS, ops
- **Hiring timeline**: When for each role?
- **Remote vs office**: Team structure strategy
- **Compensation strategy**: How to compete for talent
- **Advisory needs**: Industry, technical, marketing, sales, financial, legal

### Section 6: Customer Success

- **Health metrics**: Usage tracking, NPS, support volume, feature adoption
- **Support channels**: Current and planned
- **Response time targets**
- **Self-service**: Docs, FAQs, video tutorials, community
- **Onboarding**: Success rate, time to value, automation opportunities

### Section 7: Risk Management

- **Top 5 business risks**: With probability and impact ratings
- **Mitigation strategies**: For each major risk
- **Business continuity**: Backups, alternatives, reserves, key person documentation
- **Security maturity**: SOC 2, ISO 27001, penetration testing schedule
- **IP protection**: Trademarks, patents, trade secrets, employee agreements

### Section 8: Exit Strategy

- **5-year vision**: What does success look like?
- **Exit preference**: Hold, strategic acquisition, PE, IPO, merge
- **Potential acquirers**: Who might want this business?
- **Value creation**: What makes this business valuable to a buyer?

### Generate Document

Save completed questionnaire to:
```
projects/{project-codename}/scaleup-questionnaire.md
```

## Post-Completion

This questionnaire should be **revisited every 6-12 months**. Remind the user to schedule a review.

---

*Scale-up planning requires honest assessment of current performance and realistic growth targets. Challenge optimistic assumptions constructively.*
