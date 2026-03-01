---
name: legal-guide
description: >
  French micro-entreprise legal and administrative reference for SaaS founders.
  Use when the user asks about business registration in France, micro-entreprise rules,
  French tax obligations, VAT for SaaS, APE codes, SIRET, social contributions,
  GDPR compliance, business naming rules, insurance, or scaling beyond micro-entreprise limits.
  Also triggers for questions about French business structure, CFE, or EU digital services tax.
---

# French Micro-Entreprise Legal & Administrative Guide

## Important Disclaimer

This guide provides general reference information. Always consult a qualified French accountant (expert-comptable) or legal advisor for complex situations or significant business decisions. Tax rates and thresholds may change annually — verify current figures with official sources.

## Profile Integration

If `profiles/business-profile.md` exists, check:
- **Business structure**: Are they already registered or planning to?
- **Country**: Is France relevant? If not, note this guide is France-specific.
- **Revenue model**: Subscription vs services vs commerce affects tax classification.
- **Geographic market**: International sales trigger VAT complications.

If no profile exists, ask the user to confirm they're operating or planning to operate in France before proceeding.

---

## Micro-Entreprise Overview

### Key Characteristics
- Simplified registration via single online declaration
- Simplified accounting: basic revenue tracking (no balance sheet)
- Flat-rate tax system (micro-social regime)
- Simplified social security payments
- Annual turnover limits apply

### 2025 Turnover Limits
- **Services (BIC)**: €188,700/year
- **Sales/Commerce (BNC)**: €77,700/year
- **Mixed Activity**: Separate limits for each category

> ⚠️ Verify current limits at [autoentrepreneur.urssaf.fr](https://autoentrepreneur.urssaf.fr/) — these change periodically.

### Who This Suits
- Solo founders bootstrapping their first product
- Freelancers and consultants
- Side projects alongside employment
- Testing a business idea before committing to a heavier structure

### Who Should Consider Other Structures
- Teams (micro-entreprise = solo only, no employees)
- Revenue approaching limits → SARL or SAS
- Need to deduct significant expenses → régime réel
- Seeking investors → SAS preferred

---

## Registration Process

### Required Information
- Full name, address, nationality
- Precise business activity description (APE code)
- Business address (can be personal residence)
- Bank account (dedicated business account recommended)
- Professional liability insurance (if required by activity)

### Steps
1. **Online declaration**: [autoentrepreneur.urssaf.fr](https://autoentrepreneur.urssaf.fr/)
2. **Activity classification**: Select appropriate APE code
3. **Tax regime**: Choose micro-social (recommended for simplicity)
4. **Identity verification**: Submit required documents
5. **SIRET assigned**: Business identification number issued

### SaaS-Relevant APE Codes
- **6201Z**: Computer programming activities (primary for SaaS)
- **6202A**: Computer consultancy activities (if also consulting)
- **6311Z**: Data processing, hosting (if infrastructure-focused)

---

## Tax Obligations

### Micro-Social Regime (Recommended for SaaS)
- **Rate**: ~22% of revenue for services (BIC category)
- **Includes**: Social contributions, health insurance, retirement
- **Declarations**: Monthly or quarterly revenue reporting
- **Payment**: Based on actual revenue (no revenue = no payment)

### VAT (TVA)

| Situation | Rule |
|-----------|------|
| Below €36,800/year (services) | VAT exempt (franchise en base de TVA) |
| Above threshold | Must register for VAT, charge and collect |
| Selling to EU businesses | Reverse charge mechanism |
| Selling to EU consumers (digital) | OSS (One-Stop-Shop) for VAT in each country |
| Selling outside EU | Generally exempt from French VAT |

> ⚠️ SaaS sold to EU consumers is classified as digital services with specific VAT rules. Research OSS (One-Stop-Shop) registration requirements.

### Income Tax
- Micro-entreprise revenue declared on personal income tax return
- Option: Versement libératoire (flat rate ~2.2% on revenue, if eligible)
- Without versement libératoire: revenue added to household income at progressive rates

### CFE (Local Business Tax)
- Cotisation Foncière des Entreprises
- Due annually, even with low revenue
- Exempt in first calendar year of activity

---

## Business Naming Rules

### Legal Requirements
- Must be unique (not duplicate existing registered names)
- Must reflect actual business activity
- No misleading or inappropriate terms
- Business name (nom commercial) distinct from legal entity

### Naming Checklist
- [ ] Domain availability (.fr, .com)
- [ ] Trademark search on INPI database
- [ ] Social media handle availability
- [ ] App store name availability
- [ ] No conflicts with existing French businesses
- [ ] GitHub organization name available

### Prohibited
- Terms suggesting official status without authorization
- Names identical to existing famous brands
- Misleading activity descriptions

---

## SaaS-Specific Considerations

### Revenue Recognition
- **Subscriptions**: Revenue recognized when payment received
- **Annual plans**: Can be recognized monthly or at payment (simplified regime)
- **Refunds**: Must be documented and deducted from declarations

### International Sales
- EU customers: VAT complications above thresholds (see VAT section)
- Non-EU sales: Generally exempt from French VAT
- GDPR applies to ALL users with EU data
- Consumer protection laws apply

### Digital Services Tax
- Only applies above significant revenue thresholds (€750M global)
- Not relevant for micro-entreprise but worth knowing for scaling plans

---

## Banking & Payments

### Account Requirements
- Dedicated business account: **mandatory** above €10,000 annual revenue
- Strongly recommended even below threshold (simplifies accounting)
- Compare fees: online banks (Qonto, Shine) vs traditional banks

### Payment Processing for SaaS
- **Stripe**: Best for international SaaS, handles EU VAT automatically
- **PayPal**: Alternative, but higher fees for subscriptions
- Ensure payment processor provides proper invoicing for French requirements

---

## Insurance

### Recommended Coverage
- **Professional liability** (RC Pro): Covers software errors, bad advice
- **Cyber liability**: Data breach coverage (important for SaaS)
- **General liability**: Basic business operations coverage

### When Mandatory
- Some professions require specific insurance
- SaaS generally not mandatory but strongly recommended
- Check your APE code requirements

---

## Ongoing Obligations

### Monthly/Quarterly
- [ ] Declare revenue (even if zero)
- [ ] Pay social contributions
- [ ] Maintain invoice records
- [ ] Track expenses (for personal reference, not deductible in micro)

### Annually
- [ ] Personal income tax declaration (include business revenue)
- [ ] Pay CFE
- [ ] Review insurance coverage
- [ ] Check if approaching turnover limits

---

## Scaling Beyond Micro-Entreprise

### Warning Signs You're Outgrowing It
- Revenue approaching annual limits
- Need to hire employees
- Significant deductible expenses (can't deduct in micro regime)
- Seeking investment (investors prefer SAS)
- Multiple founders

### Transition Options
- **SARL**: Limited liability, simpler governance, good for small teams
- **SAS**: Most flexible, preferred by investors, scalable
- **EURL**: Single-person SARL (if you want liability protection but stay solo)

### Relocation Considerations
- Some founders consider Switzerland, Ireland, Estonia, or Nordic countries
- Tax optimization is legal but research thoroughly
- EU e-Residency (Estonia) allows remote company formation
- Consider substance requirements (you may need real presence)

---

## Quick Reference

### Key Websites
- Registration: [autoentrepreneur.urssaf.fr](https://autoentrepreneur.urssaf.fr/)
- Tax info: [impots.gouv.fr](https://www.impots.gouv.fr/)
- Trademark search: [data.inpi.fr](https://data.inpi.fr/)
- Business info: [entreprendre.service-public.fr](https://entreprendre.service-public.fr/)

### Key Numbers to Track
- Annual revenue vs limits (€188,700 services / €77,700 commerce)
- VAT threshold (€36,800 services)
- Monthly/quarterly declaration deadlines
- CFE payment deadline (December 15)

---

*This guide covers French micro-entreprise essentials for SaaS founders. For complex situations (multiple activities, international structures, significant revenue), consult a professional.*
