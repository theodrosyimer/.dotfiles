---
name: email-marketing
description: >
  Create email marketing sequences and automation for SaaS products.
  Use when the user asks for welcome emails, onboarding sequences, re-engagement campaigns,
  trial conversion emails, churn prevention, transactional emails, NPS surveys,
  feature announcements, payment failure handling, or any customer email communication.
  Generates ready-to-use email copy with subject lines, timing, and content structure.
  Supports both English and French email generation.
---

# Email Marketing Sequences & Automation

## Profile Integration

If `profiles/business-profile.md` exists, check:
- **Language preferences**: Generate emails in the appropriate language(s)
- **Brand tone**: Match the user's brand personality
- **Target market**: Adapt cultural references and expectations
- **Product type**: Consumer app vs B2B SaaS affects tone and complexity

If no profile, ask: "What language should the emails be in? What's the product and who's it for?"

---

## Core Principles

Apply these to ALL generated emails:

1. **Personalization**: Address users by name, reference their specific actions
2. **Value-first**: Every email provides clear value before asking for anything
3. **Progressive disclosure**: Gradually introduce features and concepts
4. **Single CTA**: One prominent call-to-action per email
5. **Mobile-first**: All emails must work on mobile (short paragraphs, big buttons)
6. **Compliance**: GDPR consent, easy unsubscribe, clear sender identification

---

## Available Sequences

When the user asks for email help, identify which sequence type they need:

### 1. Welcome Series (New User Onboarding)

**5 emails over 14 days**

| Email | Timing | Subject Pattern | Goal |
|-------|--------|----------------|------|
| 1. Welcome | Immediate | "Welcome to [Product]! Your first step" | Confirm signup, set expectations |
| 2. Getting Started | Day 1 | "Your quick start guide" | Guide to first valuable action |
| 3. Feature Highlight | Day 3 | "Discover what our users love most" | Introduce key differentiator |
| 4. Tips & Best Practices | Day 7 | "5 tips to maximize your results" | Deepen engagement |
| 5. Check-in | Day 14 | "How's it going? We're here to help" | Assess progress, prevent churn |

### 2. Re-engagement (Inactive Users)

**7-Day Inactivity (3 emails)**

| Email | Timing | Goal |
|-------|--------|------|
| 1. Gentle reminder | Day 7 inactive | Remove barriers, easy return path |
| 2. Value reinforcement | Day 10 inactive | Show what they're missing, social proof |
| 3. Help offer | Day 14 inactive | Personal support, FAQ links |

**30-Day Inactivity (2 emails)**

| Email | Timing | Goal |
|-------|--------|------|
| 1. We miss you | Day 30 | Account status, improvements since last visit |
| 2. Final attempt | Day 45 | Account expiration warning, data export offer |

### 3. Free Trial → Paid Conversion

**5 emails over trial period**

| Email | Timing | Goal |
|-------|--------|------|
| 1. Trial welcome | Immediate | Set expectations, guide to quick wins |
| 2. Mid-trial check-in | 50% through | Assess progress, provide support |
| 3. Trial ending soon | 3 days before end | Create urgency, highlight value received |
| 4. Last day | Final day | Final conversion push |
| 5. Trial expired | Day after | Conversion or re-engagement offer |

### 4. Customer Success (Milestone Celebrations)

| Trigger | Subject Pattern | Goal |
|---------|----------------|------|
| First achievement | "Congrats! You reached your first goal" | Celebrate, encourage continued use |
| Usage milestone | "Amazing! You've [specific achievement]" | Positive reinforcement |
| Feature adopted | "You're now using [Feature] like a pro" | Encourage deeper usage |

### 5. Feature Adoption

**3-email sequence per major feature**

| Email | Timing | Goal |
|-------|--------|------|
| 1. Announcement | Launch + 7 days | Announce and encourage trial |
| 2. Tutorial | If unused after 14 days | Reduce adoption barriers |
| 3. Success stories | If unused after 30 days | Social proof and use cases |

### 6. Transactional

| Email | Trigger | Goal |
|-------|---------|------|
| Payment confirmation | After successful payment | Confirm, provide receipt |
| Payment failed | After failed payment | Resolve quickly, prevent churn |
| Subscription renewed | After renewal | Confirm, reinforce value |
| Cancellation | After cancel request | Confirm, offer alternatives |

### 7. Feedback & Surveys

| Email | Timing | Goal |
|-------|--------|------|
| NPS survey | 30 days after signup or quarterly | Measure satisfaction |
| Detailed feedback | Based on NPS score | Specific improvement suggestions |
| Feature request | Quarterly to engaged users | Product development insights |

---

## Email Generation Template

When generating an email, always provide:

```
**Sequence**: [Which sequence this belongs to]
**Email #**: [Position in sequence]
**Trigger**: [What causes this email to send]
**Timing**: [When relative to trigger]
**Subject line**: [Primary subject]
**Subject line B** (A/B test): [Alternative subject]
**Preview text**: [First line visible in inbox]
**Goal**: [What this email should achieve]

---

[Email body here — use markdown formatting]

---

**CTA**: [Button text] → [Where it links]
**Fallback CTA**: [Text link alternative]
```

---

## Bilingual Support

### French Email Patterns
- Use formal "vous" by default for B2B, ask about "tu" for consumer apps
- Subject lines: shorter is better, avoid anglicisms when a French word exists
- Comply with French email marketing law (Loi Informatique et Libertés + GDPR)
- Include "Se désabonner" (unsubscribe) prominently
- Sender name: use a person's name + company ("Marie de [Product]")

### English Email Patterns
- More casual tone acceptable, especially for consumer products
- Subject lines: can be longer, use curiosity and urgency
- CAN-SPAM compliance for US recipients
- Sender: company name or founder name depending on brand personality

---

## Technical Specifications

### Deliverability Checklist
- [ ] Dedicated sending domain (not personal email)
- [ ] SPF, DKIM, and DMARC configured
- [ ] Regular list hygiene (remove bounces, clean inactive)
- [ ] Avoid spam trigger words
- [ ] Warm up new sending domains gradually

### Performance Targets

| Metric | SaaS Benchmark | Action Threshold |
|--------|---------------|------------------|
| Open rate | 25-35% | Below 20% → fix subject lines |
| Click rate | 3-10% | Below 2% → fix content/CTA |
| Unsubscribe | <2% | Above 2% → review frequency/relevance |
| Conversion | Varies by type | Track per sequence for optimization |

### A/B Testing Priority
1. Subject lines (highest impact)
2. Send time (day and hour)
3. CTA text and placement
4. Email length
5. Personalization depth

---

## Workflow

When a user asks for email help:

1. **Identify the sequence type** from the list above
2. **Check profiles** for language, tone, and product details
3. **Ask what's missing**: product name, key features, target audience (if not in profile)
4. **Generate the full sequence** with all emails, using the generation template
5. **Offer variations**: "Want me to generate A/B test versions for the subject lines?"
6. **Suggest implementation**: Recommend email service based on tech preferences if available

---

*Generate complete, ready-to-implement email sequences. Always include subject lines, timing, content, and CTAs. Adapt tone to the user's brand and market.*
